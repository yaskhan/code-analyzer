//! Mathematical operations module
//! Provides basic mathematical functions and utilities

const std = @import("std");

/// Point structure representing a 2D coordinate
pub const Point = struct {
    x: f64,
    y: f64,
    
    /// Creates a new point with given coordinates
    pub fn new(x: f64, y: f64) Point {
        return Point{ .x = x, .y = y };
    }
    
    /// Calculates distance from origin
    pub fn distanceFromOrigin(self: Point) f64 {
        return std.math.sqrt(self.x * self.x + self.y * self.y);
    }
};

/// Rectangle structure
const Rectangle = struct {
    width: f64,
    height: f64,
    
    pub fn area(self: Rectangle) f64 {
        return self.width * self.height;
    }
    
    pub fn perimeter(self: Rectangle) f64 {
        return 2.0 * (self.width + self.height);
    }
};

/// Adds two numbers together
pub fn add(a: f64, b: f64) f64 {
    return a + b;
}

/// Subtracts second number from first
pub fn subtract(a: f64, b: f64) f64 {
    return a - b;
}

/// Multiplies two numbers
pub fn multiply(a: f64, b: f64) f64 {
    return a * b;
}

/// Divides first number by second
pub fn divide(a: f64, b: f64) !f64 {
    if (b == 0) {
        return error.DivisionByZero;
    }
    return a / b;
}

/// Calculates the square of a number
fn square(x: f64) f64 {
    return x * x;
}

/// Calculates the cube of a number
fn cube(x: f64) f64 {
    return x * x * x;
}
