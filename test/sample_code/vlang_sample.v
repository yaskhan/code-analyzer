module test

// Test module for VLang parser

// Public constant
pub const max_size = 100

// Private constant
const min_size = 10

// Public enum
pub enum Color {
    red
    green
    blue
}

// Private enum
enum Status {
    pending
    active
    completed
}

// Public struct
pub struct User {
    name string
    age  int
mut:
    mutable_age int
}

// Public struct with mut
pub struct Config {
mut:
    port     int
    hostname string
}

// Private struct
struct InternalData {
    id    int
    value string
}

// Public interface
pub interface Writer {
    write(data string) bool
}

// Interface with implements
pub interface Reader {
    read() string
}

// Public function
pub fn get_user(id int) ?User {
    return User{}
}

// Private function
fn validate_user(u User) bool {
    return true
}

// Public method
pub fn (u User) get_name() string {
    return u.name
}

// Method with mut receiver
pub fn (mut u User) set_age(age int) {
    u.mutable_age = age
}

// Match expression
fn process_color(c Color) {
    match c {
        .red { println('red') }
        .green { println('green') }
        .blue { println('blue') }
    }
}

// Function with optional type
fn find_user(id int) ?User {
    return none
}

// Function with voidptr
fn to_voidptr(ptr voidptr) int {
    return 0
}
