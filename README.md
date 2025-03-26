# MyPrintf

В данном проекте я написал функцию ```MyPrintf ()``` подобную стандартной функции  язков C и C++.
Данная функция написана на ***nasm x86-64*** на операционной системе ***Linux***, поэтому данная программа <span style="color:red; font-weight:bold; text-decoration:underline">не поддерживается</span> с другими ОС и архитектурами компьютера.

## Особенности
* Прототип функции
```cpp
void MyPrintf(const char* format, ...);
```

* Поддерживаемые спецификаторы
1. ```%b``` - для числа в двоичном формате
2. ```%o``` - для числа в восьмиричном формате
3. ```%d``` - для числа в десятичном формате
4. ```%h``` - для числа в шестнадцатиричном формате формате
5. ```%c``` - для одного символа
6. ```%s``` - для строки
7. ```%%``` - для вывода самого знака '%'


* Пример использования
```cpp
MyPrintf ("Mathematical %s: %o + (%d) + %b - %x %c %d\n",
          "facts", 04, -2, 0b100, 0x50,'=', 52);
```

Вот как выглядит результат вывода в консоль

```cpp
Mathematical facts: 4 + (-2) + 100 - 50 = 52
```
## Сборка на Linux
```bash
sudo apt update
sudo apt install make g++ nasm
git clone https://GitHub.com/dangerUser45/MyPrintf/
cd MyPrintf
make
```

## Как свазять С/С++ и nasm
Чтобы вы могли использовать эту функцию в языках более высокого уровня, например в С++ вы должны объявить эту функцию так:
```cpp
extern "C" void MyPrintf(const char* format, ...);
```
Полный пример для запуска в C++:
```cpp
extern "C" void MyPrintf(const char* format, ...);

int main ()
{
    MyPrintf ("Mathematical %s: %o + (%d) + %b - %x %c %d\n",
              "facts", 04, -2, 0b100, 0x50,'=', 52);
}
```

