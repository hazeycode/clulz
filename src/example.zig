const clulz = @import("main.zig");

pub fn main() !void {
    try clulz.printDefaultWelcome("clulz example (version 0.0.0)");
    
    const Context = struct {
        quit: bool = false,
    };
    
    var context = Context{};
    
    while (context.quit == false) {
        _ = try clulz.promptCommand("example> ", &context, &[_]clulz.CommandDescriptor{
            .{
                .command = "greet",
                .description = "Prints a greeting",
                .args = struct { name: []const u8 },
                .proc = greet,
            },
            .{
                .command = "quit",
                .description = "Terminate the program",
                .args = struct {},
                .proc = quit,  
            },
        });
    }
}

fn greet(args: anytype, _: anytype) void {
    clulz.println("Hi, {s}!", .{args.name}) catch unreachable;
}

fn quit(_: anytype, context: anytype) void {
    context.*.quit = true;
}
