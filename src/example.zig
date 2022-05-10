const clulz = @import("clulz.zig");

pub fn main() !void {
    try clulz.printDefaultWelcome("clulz example (version 0.0.0)");
    
    var context = struct {
        quit: bool = false,
    }{};
   
    while (context.quit == false) {
        _ = try clulz.promptCommand("example> ", &context, &.{
            clulz.CommandDescriptor{
                .command = "greet",
                .description = "Print a greeting",
                .args = struct { name: []const u8 },
                .proc = greet,
            },
            clulz.CommandDescriptor{
                .command = "quit",
                .description = "Terminate the program",
                .args = struct {},
                .proc = quit,  
            },
        });
    }
}

fn greet(args: anytype, _: anytype) !void {
    try clulz.println("Hi, {s}!", .{args.name});
}

fn quit(_: anytype, context: anytype) !void {
    context.*.quit = true;
}

