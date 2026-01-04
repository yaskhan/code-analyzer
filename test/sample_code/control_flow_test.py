# Test file with control flow statements
def test_function(x):
    if x > 0:
        return "positive"
    elif x < 0:
        return "negative"
    else:
        return "zero"

class TestClass:
    def method1(self):
        if True:
            return 1
        elif False:
            return 2
    
    def method2(self):
        for i in range(10):
            if i % 2 == 0:
                print("even")
            elif i % 3 == 0:
                print("divisible by 3")

def another_function():
    while True:
        if condition:
            break
        elif other_condition:
            continue
</parameter>
</write_to_file>

[Response interrupted by a tool use result. Only one tool may be used at a time and should be placed at the end of the message.]