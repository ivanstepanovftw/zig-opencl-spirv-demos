// https://github.com/ziglang/zig/issues/24281
const std = @import("std");
const cl = @import("opencl");
const common = @import("common.zig");

pub const std_options = common.std_options;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const platform, const device = try common.parseOptions(allocator);

    const context = try cl.createContext(&.{device}, .{ .platform = platform });
    defer context.release();

    const queue = try cl.createCommandQueue(context, device, .{ .profiling = true });
    defer queue.release();

    const program = try common.buildSpvProgram(allocator, context, device, @embedFile("miscomp-kernel"));
    defer program.release();

    const kernel = try cl.createKernel(program, "miscomp");
    defer kernel.release();

    const size = 1024;
    const value: u64 = 42;

    const data = try allocator.alloc(i8, size);
    @memset(data, 0);

    const d_data = try cl.createBuffer(i8, context, .{ .write_only = true }, size);
    defer d_data.release();

    try kernel.setArg(@TypeOf(d_data), 0, d_data);
    try kernel.setArg(u64, 1, value);

    const kernel_complete = try queue.enqueueNDRangeKernel(
        kernel,
        null,
        &.{size},
        &.{256},
        &.{},
    );
    defer kernel_complete.release();
    
    const read_complete = try queue.enqueueReadBuffer(
        i8,
        d_data,
        false,
        0,
        data,
        &.{kernel_complete},
    );
    defer read_complete.release();

    try cl.waitForEvents(&.{read_complete});

    std.debug.print("Data after kernel execution: {any}\n", .{data});
}
