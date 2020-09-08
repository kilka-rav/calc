# калькулятор в польской нотации
# запуск
nasm -f elf64 calc.nasm
gcc -static -o calc calc.o
./calc
пример ввода: 2 pi * cos sin = sin(cos(2pi))
поддерживаемые функции: ln, lg, sin, cos, tg, ctg, ^, sqrt, +, -, *, /, load pi
