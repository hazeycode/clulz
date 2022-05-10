# clulZ
A work-in-progress **c**ommand-**l**ine **u**tility **l**ibrary for [**Z**ig](https://ziglang.org/) programs.

Provides a semi-declarative, allocation-free API for building CLI programs.

__NOTE__: Blocked by comptime bugs in Zig stage 1. Looking for a temporary workaround for compiler crash when multiple args are specified in `CommandDescriptors`.

Tracking the latest Zig release, currently verison 0.9.1

## Usage

To simply prompt for a value, `prompt` can be used, which will attempt to parse user as the specified type, for example:
```zig
const answer = try clulz.prompt(u32, "How much wood would a woodchuck chuck if a woodchuck could chuck wood? ");
```

`promptCommand` can be used to prompt for input that is mapped to some command, as defined by `CommandDescriptor`s, a bool indicating whether a command was invoked is returned, for example:
```zig
_ = try clulz.promptCommand("example> ", .{}, &[_]clulz.CommandDescriptor{
    .{
        .command = "greet",
        .description = "Print a greeting",
        .args = struct { name: []const u8 },
        .proc = greet,
    },
};

fn greet(args: anytype, _: anytype) void {
    clulz.println("Hi, {s}!", .{args.name}) catch unreachable;
}
```

The user may enter any number of arguments for a specific command, if less arguments are entered than the command proc takes then the user will be prompted for each missing argument:
```
example> greet   
enter name: Ziggy
Hi, Ziggy!
```

A builtin `help` command is derived from the defined `CommandDescriptor`s


See [example.zig](src/example.zig) for a more complete usage example. To run it:
```sh
zig run src/example.zig
```
