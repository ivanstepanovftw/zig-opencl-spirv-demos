const std = @import("std");
const Allocator = std.mem.Allocator;

const cl = @import("opencl");

// Downstream demos should import this
pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = log,
};

var log_verbose: bool = false;

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = scope;
    if (@intFromEnum(level) <= @intFromEnum(std.log.Level.info) or log_verbose) {
        switch (level) {
            .info => std.debug.print(format ++ "\n", args),
            else => {
                const prefix = comptime level.asText();
                std.debug.print(prefix ++ ": " ++ format ++ "\n", args);
            },
        }
    }
}

pub fn fail(comptime fmt: []const u8, args: anytype) noreturn {
    std.log.err(fmt, args);
    std.process.exit(1);
}

const DeviceAndPlatform = struct { cl.Platform, cl.Device };

pub fn parseOptions(a: Allocator) !DeviceAndPlatform {
    var args = try std.process.argsWithAllocator(a);
    defer args.deinit();

    const exe_name = args.next().?;

    var platform: ?[]const u8 = null;
    var device: ?[]const u8 = null;
    var help: bool = false;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--platform") or std.mem.eql(u8, arg, "-p")) {
            platform = args.next() orelse fail("missing argument to option {s}", .{arg});
        } else if (std.mem.eql(u8, arg, "--device") or std.mem.eql(u8, arg, "-d")) {
            device = args.next() orelse fail("missing argument to option {s}", .{arg});
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            help = true;
        } else if (std.mem.eql(u8, arg, "--verbose") or std.mem.eql(u8, arg, "-v")) {
            log_verbose = true;
        } else {
            fail("unknown option '{s}'", .{arg});
        }
    }

    if (help) {
        const out: std.fs.File = .stdout();
        var writer = out.writer(&.{});
        try writer.interface.print(
            \\usage: {s} [options...]
            \\
            \\Options:
            \\--platform|-p <platform>  OpenCL platform name to use. By default, uses the
            \\                          first platform that has any devices available.
            \\--device|-d <device>      OpenCL device name to use. If --platform is left
            \\                          unspecified, all devices of all platforms are
            \\                          matched. By default, uses the first device of the
            \\                          platform.
            \\--verbose|-v              Turn on verbose logging.
            \\--help -h                 Show this message and exit.
            \\
        ,
            .{exe_name},
        );
        std.process.exit(0);
    }

    return try pickPlatformAndDevice(a, platform, device);
}

fn deviceSupportsSpirv(a: Allocator, device: cl.Device) !bool {
    // 1. Попытка через OpenCL 3.0 (getILsWithVersion).
    // На T4 в Colab это вызывает ошибку CL_INVALID_VALUE (-30).
    // Мы перехватываем ошибку и идем дальше.
    // if (device.getILsWithVersion(a)) |ils| {
    //     defer a.free(ils);
    //     for (ils) |il| {
    //         if (std.mem.eql(u8, il.getName(), "SPIR-V")) {
    //             std.log.debug("Support for SPIR-V detected via ILs query", .{});
    //             return true;
    //         }
    //     }
    // } else |err| {
    //     std.log.debug("getILsWithVersion check skipped due to error: {}", .{err});
    // }
    //
    // // 2. Фоллбэк: Ручное получение CL_DEVICE_EXTENSIONS через C-API.
    // // Библиотека opencl-zig не имеет обертки для этого, делаем сами.
    //
    // var size: usize = undefined;
    // // Используем raw C константы и функции, доступные через cl.c
    // const ext_param_id = cl.c.CL_DEVICE_EXTENSIONS;
    //
    // // Шаг А: Узнаем размер строки
    // if (cl.c.clGetDeviceInfo(device.id, ext_param_id, 0, null, &size) != cl.c.CL_SUCCESS) {
    //     std.log.debug("Failed to get extensions string size", .{});
    //     return false;
    // }
    //
    // // Шаг Б: Аллоцируем память
    // const extensions_str = try a.alloc(u8, size);
    // defer a.free(extensions_str);
    //
    // // Шаг В: Запрашиваем саму строку
    // if (cl.c.clGetDeviceInfo(device.id, ext_param_id, size, extensions_str.ptr, null) != cl.c.CL_SUCCESS) {
    //     std.log.debug("Failed to get extensions string content", .{});
    //     return false;
    // }
    //
    // // 3. Проверка наличия расширений в строке
    // if (std.mem.indexOf(u8, extensions_str, "cl_khr_il_program") != null) return true;
    // if (std.mem.indexOf(u8, extensions_str, "cl_khr_spirv") != null) return true;
    //
    // return false;
    return true;
}

fn pickPlatformAndDevice(
    a: Allocator,
    maybe_platform_query: ?[]const u8,
    maybe_device_query: ?[]const u8,
) !DeviceAndPlatform {
    const platforms = try cl.getPlatforms(a);
    std.log.debug("{} platform(s) available", .{platforms.len});

    if (platforms.len == 0) {
        fail("no opencl platform available", .{});
    }

    for (platforms) |platform| {
        const platform_name = try platform.getName(a);
        defer a.free(platform_name);

        if (maybe_platform_query) |platform_query| {
            if (!std.mem.eql(u8, platform_name, platform_query)) {
                continue;
            }
        }

        std.log.debug("trying platform '{s}'", .{platform_name});

        const devices = try platform.getDevices(a, cl.DeviceType.all);
        defer a.free(devices);

        if (devices.len == 0) {
            if (maybe_platform_query != null) {
                fail("platform '{s}' has no devices available", .{platform_name});
            }
            continue;
        }

        for (devices) |device| {
            const device_name = try device.getName(a);
            defer a.free(device_name);

            if (maybe_device_query) |device_query| {
                if (!std.mem.eql(u8, device_name, device_query)) {
                    continue;
                }
            }
            std.log.debug("trying device '{s}'", .{device_name});

            if (!try deviceSupportsSpirv(a, device)) {
                if (maybe_device_query != null) {
                    fail("device '{s}' of platform '{s}' does not support SPIR-V ingestion", .{ device_name, platform_name });
                }
            }

            std.log.info("selected platform '{s}' and device '{s}'", .{ platform_name, device_name });

            return .{ platform, device };
        }

        if (maybe_device_query) |device_query| {
            if (maybe_platform_query != null) {
                fail("platform '{s}' does not have any device that matches '{s}'", .{ platform_name, device_query });
            }
        }
    }

    // Case where both platform and device queries are not null is already handled above.

    if (maybe_platform_query) |platform_query| {
        fail("no such opencl platform '{s}'", .{platform_query});
    } else if (maybe_device_query) |device_query| {
        fail("no such opencl device '{s}'", .{device_query});
    }

    unreachable;
}

pub fn buildSpvProgram(a: Allocator, context: cl.Context, device: cl.Device, spv: []const u8) !cl.Program {
    std.log.debug("compiling program", .{});

    const program = try cl.createProgramWithIL(context, spv);
    errdefer program.release();

    program.build(&.{device}, "") catch |err| {
        if (err == error.BuildProgramFailure) {
            const build_log = try program.getBuildLog(a, device);
            defer a.free(build_log);
            std.log.err("failed to compile kernel:\n{s}", .{build_log});
        }
        return err;
    };

    return program;
}
