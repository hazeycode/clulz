# clulz
A **c**ommand-**l**ine **u**tility **l**ibrary for **z**ig programs.

Provides a semi-declarative, allocation-free API for building CLI programs. WIP.

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

To simply prompt for a value, `prompt` can be used, which will attempt to parse user as the specified type, for example:
```zig
const answer = try clulz.prompt(u32, "How much wood would a woodchuck chuck if a woodchuck could chuck wood? ");
```

See [example.zig](src/example.zig) for a more complete usage example. To run it:
```sh
zig build example
```

Only this basic functionality is provided right now. Fancy features and improvements will be added per demand. If there's a particular feature that you want to see, feel free to open an issue describing it. Pull requests are also welcome. NOTE: by contributing code, you must have ownership or permission to do so and agree to license it under [the same license as the project](./LICENSE)

Tracking the latest Zig release, currently verison 0.9.1
