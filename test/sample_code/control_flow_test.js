// Test file with control flow statements
function testFunction(x) {
    if (x > 0) {
        return "positive";
    } else if (x < 0) {
        return "negative";
    } else {
        return "zero";
    }
}

class TestClass {
    method1() {
        if (true) {
            return 1;
        } else if (false) {
            return 2;
        }
    }
    
    method2() {
        for (let i = 0; i < 10; i++) {
            if (i % 2 === 0) {
                console.log("even");
            } else if (i % 3 === 0) {
                console.log("divisible by 3");
            }
        }
    }
}

function anotherFunction() {
    while (true) {
        if (condition) {
            break;
        } else if (otherCondition) {
            continue;
        }
    }
}