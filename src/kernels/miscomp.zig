// https://github.com/ziglang/zig/issues/24281
export fn miscomp(y: [*]addrspace(.global) i8, a: u64) callconv(.Kernel) void {
    const gid = @workGroupId(0) * @workGroupSize(0) + @workItemId(0);
    // y[gid] = @as(i8, @intCast(a)); // no bug
    y[gid] = @as(i8, @intCast(a)) - 0; // bug
}
