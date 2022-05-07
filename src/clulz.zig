const std = @import("std");

const max_input_len = 1024;

/// Just a wrapper for printing a line of text to stdout
pub fn println(comptime fmt: []const u8, args: anytype) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(fmt, args);
    try stdout.writeByte('\n');
}

/// Prints a default welcome message for REPL CLIs, provied for convenience
pub fn printDefaultWelcome(app_name_and_ver: []const u8) !void {
    try println("Welcome to {s}", .{app_name_and_ver});
    try println("Type `help` for a list of available commands.", .{});
}

/// Prints the given prompt string and attempts to parse the input from the user as the given type
pub fn prompt(comptime T: type, prompt_str: []const u8) !?T {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    try stdout.writeAll(prompt_str);

    var user_input_buf: [max_input_len]u8 = undefined;
    const user_input = try stdin.readUntilDelimiter(user_input_buf[0..], '\n');

    return parse(T, user_input) catch {
        try println("Invalid input. Expected {s}", .{typeName(T)});
        return null;
    };
}

pub const CommandDescriptor = struct {
    command: []const u8,
    description: []const u8,
    args: type,
    proc: fn (args: anytype, context: anytype) void,
};

/// Prints the given prompt, parses input from stdin and maps it to the given commands
pub fn promptCommand(
    prompt_str: []const u8,
    context: anytype,
    cmds: []const CommandDescriptor,
) !bool {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    try stdout.writeAll(prompt_str);

    const max_input_words = 16;

    var user_input_words_buf: [max_input_words][]u8 = undefined;

    const words = parseUserInput: {
        var user_input_buf: [max_input_len]u8 = undefined;
        const user_input = try stdin.readUntilDelimiter(user_input_buf[0..], '\n');

        var i: usize = 0;
        var j: usize = 0;

        while (i < user_input.len) : (i += 1) {
            if (std.ascii.isSpace(user_input[i])) {
                continue;
            }

            const word_start = i;
            var word_end = i;
            while (i < user_input.len) : ({
                i += 1;
                word_end += 1;
            }) {
                if (std.ascii.isSpace(user_input[i])) {
                    break;
                }
            }

            const word = user_input[word_start..word_end];
            user_input_words_buf[j] = word;
            j += 1;
        }

        break :parseUserInput user_input_words_buf[0..j];
    };

    if (words.len == 0) {
        return false;
    }

    const command_word = words[0];
    const arg_words = words[1..];

    if (std.mem.eql(u8, command_word, "help")) {
        inline for (cmds) |cmd_desc| {
            try stdout.print("\n{s}:\n{s}", .{ cmd_desc.description, cmd_desc.command });
            inline for (std.meta.fields(cmd_desc.args)) |arg_field| {
                try stdout.print(" <{s}>", .{arg_field.name});
            }
            try stdout.print("\n", .{});
        }
        try stdout.print("\n", .{});
        return true;
    }

    inline for (cmds) |cmd_desc| {
        if (std.mem.eql(u8, cmd_desc.command, command_word)) {
            const Args = cmd_desc.args;
            const arg_fields = std.meta.fields(Args);

            if (arg_fields.len < arg_words.len) {
                try println(
                    "Too many arguments. Type `help` for a list of available commands.",
                    .{},
                );
                return false;
            }

            var args: Args = undefined;

            var parsed_arg_count: usize = 0;
            inline for (arg_fields) |arg_field, i| {
                if (i < arg_words.len) {
                    // parse given arguments
                    const arg_word = arg_words[i];
                    const value = parse(arg_field.field_type, arg_word) catch {
                        try println(
                            "Failed to parse argument as {s}",
                            .{@typeName(arg_field.field_type)},
                        );
                        return false;
                    };
                    @field(args, arg_field.name) = value;
                    parsed_arg_count += 1;
                } else {
                    // prompt for any missing args
                    var prompt_buf: [32]u8 = undefined;
                    var attempts_remaining: u32 = 3;
                    while (true) {
                        const arg_prompt_str = try std.fmt.bufPrint(
                            &prompt_buf,
                            "enter {s}: ",
                            .{arg_field.name},
                        );

                        const maybe_value = try prompt(arg_field.field_type, arg_prompt_str);

                        const is_empty_string = if (arg_field.field_type == []const u8)
                            maybe_value.?.len == 0
                        else
                            false;

                        attempts_remaining -= 1;

                        if (maybe_value != null and is_empty_string == false) {
                            @field(args, arg_field.name) = maybe_value.?;
                            parsed_arg_count += 1;
                            break;
                        } else if (attempts_remaining > 0) {
                            try println("Invalid input. Expected {s}", .{typeName(arg_field.field_type)});
                        } else {
                            try println("Too many failed attempts. Aborting.", .{});
                            return false;
                        }
                    }
                }
            }

            cmd_desc.proc(args, context);
            return true;
        }
    }

    try println("Invalid input. Type `help` for a list of available commands.", .{});
    return false;
}

fn typeName(comptime T: type) []const u8 {
    return switch (T) {
        []const u8 => "string",
        else => switch (@typeInfo(T)) {
            .Bool => "boolean",
            .Int => "integer number",
            .Float => "real number",
            else => @compileError("Unsupported type: " ++ @typeName(T)),
        },
    };
}

fn parse(comptime T: type, string: []const u8) !T {
    var lower_str_buf: [max_input_len]u8 = undefined;
    const string_lowered = std.ascii.lowerString(&lower_str_buf, string);
    return switch (T) {
        []const u8 => string,
        else => switch (@typeInfo(T)) {
            .Bool => if (std.mem.eql(u8, string_lowered, 'y'))
                true
            else if (std.mem.eql(u8, string_lowered, 'n'))
                false
            else
                error.FailedToParseBool,
            .Int => try std.fmt.parseInt(T, string, 10),
            .Float => try std.fmt.parseFloat(T, try string),
            else => @compileError("Unsupported type: " ++ @typeName(T)),
        },
    };
}

test {
    std.testing.refAllDecls(@This());
}
