const std = @import("std");
const List = std.ArrayList;
var Allocator = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = &(Allocator).allocator;

const Position = struct { 
    x: usize, 
    y: usize
};

fn getNumberOfGroups(
    nRows: usize, nColumns: usize, aisleSeat: usize, 
    positions: []Position, groupSize: usize
) !usize {
    var total: usize = 0;
    var positionsByRow = try separatePositionsByRow(nRows, positions);
    for (positionsByRow.items) |row| {
        total += try getNumberOfGroupsInRow(
            nColumns, aisleSeat, row.items, groupSize
        ); 
    }
    // We don't need to free each row, because getNumberOfGroups takes their ownership
    positionsByRow.deinit(); 
    return total;
}

fn separatePositionsByRow(nRows: usize, positions: []Position) !List(List(usize)) {
    var result = List(List(usize)).init(allocator);
    while (result.items.len < nRows) {
        var newList = List(usize).init(allocator);
        try result.append(newList);
    }
    for (positions) |position| {
        try result.items[position.x - 1].append(position.y);
    }
    return result;
}

// Takes the ownership of the positions slice
fn getNumberOfGroupsInRow(
    rowSize: usize, aisleSeat: usize, positions: []usize, groupSize: usize
) !usize {
    // completePositions contains each position, but also the start and the end
    var completePositions = List(usize).fromOwnedSlice(allocator, positions);
    try completePositions.insert(0, 0);
    try completePositions.append(rowSize + 1);
    var total: usize = 0;
    var positionsSlice = completePositions.items;
    for (positionsSlice[0..positionsSlice.len - 1]) |position, i| {
        total += getNumberOfGroupsInFreeSpace(
            position + 1, positionsSlice[i + 1], aisleSeat, groupSize
        );
    }
    completePositions.deinit();
    return total;
}

// start inclusive, end exclusive. [start, end)
fn getNumberOfGroupsInFreeSpace(
    start: usize, end: usize, aisleSeat: usize, groupSize: usize
) usize {
    var result: usize = 0;
    var index = start;
    while (end - index >= groupSize) {
        var possible_end = index + groupSize;
        if (index == aisleSeat or aisleSeat + 2 == possible_end) {
            index += 1; 
        } else {
            index += groupSize;
            result += 1;
        }
    }
    return result;
}

const expect = std.testing.expect;

test "1.1 Von Neumann" {
    // 0 X || 0 0 0 0
    // 0 0 || 0 0 0 0
    // 0 0 || 0 0 X 0
    // 0 0 || 0 0 X 0
    {
        var positions = [_]Position{ 
            Position{ .x = 1, .y = 2 },
            Position{ .x = 3, .y = 5 },
            Position{ .x = 4, .y = 5 },
        };
        var numberOfGroups: usize = try getNumberOfGroups(4, 6, 2, &positions, 3);
        try expect(numberOfGroups == 2);
    }
}

test "1.2 Turing" {
    // 0 X || 0 0 0 0
    // 0 0 || 0 0 0 0
    // 0 0 || 0 0 X 0
    // 0 0 || 0 X 0 0
    var positions = [_]Position{
        Position{ .x = 1, .y = 2 },
        Position{ .x = 3, .y = 5 },
        Position{ .x = 4, .y = 4 },
    };
    var numberOfGroups: usize = try getNumberOfGroups(4, 6, 2, &positions, 4);
    try expect(numberOfGroups == 3);
}

test "1.3 Boole" {
    // 0 X 0 0 || 0 0
    // 0 0 X 0 || 0 X
    // 0 0 0 0 || 0 X
    // 0 0 X 0 || 0 0
    var positions = [_]Position{
        Position{ .x = 1, .y = 2 },
        Position{ .x = 2, .y = 3 },
        Position{ .x = 2, .y = 6 },
        Position{ .x = 3, .y = 6 },
        Position{ .x = 4, .y = 3 },
    };
    var numberOfGroups: usize =  try getNumberOfGroups(4, 6, 4, &positions, 2);
    try expect(numberOfGroups == 7);
}

test "2.1 Ada Byron" {
    // 0 0 0 X || 0 0 0 0
    // X X 0 0 || 0 0 X 0
    // 0 0 0 0 || 0 0 0 0
    // 0 0 0 0 || 0 0 0 X
    var positions = [_]Position{
        Position{ .x = 1, .y = 4 },
        Position{ .x = 2, .y = 1 },
        Position{ .x = 2, .y = 2 },
        Position{ .x = 2, .y = 7 },
        Position{ .x = 4, .y = 8 },
    };
    var numberOfGroups: usize = try getNumberOfGroups(4, 8, 4, &positions, 4);
    try expect(numberOfGroups == 5);
}

test "2.4 Donald Knuth" {
    // X 0 0 0 || 0 0 X 0
    // 0 0 0 X || 0 0 0 0
    // 0 X 0 0 || 0 0 0 0
    // 0 0 0 0 || 0 0 0 X
    var positions = [_]Position{
        Position{ .x = 1, .y = 1 },
        Position{ .x = 1, .y = 7 },
        Position{ .x = 2, .y = 4 },
        Position{ .x = 3, .y = 2 },
        Position{ .x = 4, .y = 8 }
    };
   var numberOfGroups: usize =  try getNumberOfGroups(4, 8, 4, &positions, 5);
   try expect(numberOfGroups == 3);
}

test "Carrel 1" {
    // 0 0 0 ||
   var numberOfGroups: usize =  try getNumberOfGroups(1, 3, 3, &[_]Position{}, 3);
    try expect(numberOfGroups == 1);
}

test "Carrel 2" {
    // 0 0 || 0
    var numberOfGroups: usize = try getNumberOfGroups(1, 3, 2, &[_]Position{}, 3);
    try expect(numberOfGroups == 0);
}

test "Carrel 3" {
    // || 0 0 0
    var numberOfGroups: usize = try getNumberOfGroups(1, 3, 0, &[_]Position{}, 3);
    try expect(numberOfGroups == 1);
}

