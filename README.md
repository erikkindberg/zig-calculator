# Zig Calculator
The humble calculator. Solves basic arithmetic operations, can handle nested expression using recursive descent parsing.
## Building and Running the Project
To build and run the project, follow these steps:

1. **Clone the repository**:
    ```sh
    git clone https://github.com/erikkindberg/zig-test.git
    cd zig-test
    ```
2. **Install zig tooling**:
    If you do not have zig installed, follow the instructions [here](https://ziglang.org/learn/getting-started/).
3. **Build and run the project**:
    ```sh
    zig build run
    ```
## Usage
* Once the project is running you are free to type an expression. Multiplication must be explicit using `*`. Addition, subtraction and divison are represented with their respective symbols:
    - Addition: `+`
    - Subtraction: `-`
    - Division: `/`
* To save the result of an expression in local memory add a semicolon and a constant name after the expression:
    ```
    2 + (5 * 4) : x
    ```
* As long as the project is running, you can then use the constant as a stand-in for a previously calculated expression
## TODO
* Make error handling less of a hatchet job
* Ditto with logging
* Delete constants from memory
* Implied multiplication 
    ```
    3(2+5) Currently resolves to 3, should resolve to 21.
    ```
## License
Do whatever you want. If this comes in handy for you, good for you.