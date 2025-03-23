#include <stdio.h>
#include "COLOR.h"
extern "C" void MyPrintf(const char* format, ...);

int main ()
{
    // MyPrintf ("%x%b\n", 0xDED, 0b101101);

    MyPrintf ("\n\t\t\t\t" YELLOW "My printf ():" RESET "\n"
            "\t\t\tFirst    arg: " GREEN "%x" RESET "\n"
            "\t\t\tSecond   arg: " GREEN "%o" RESET "\n"
            "\t\t\tThird    arg: " GREEN "%b" RESET "\n"
            "\t\t\tFourth   arg: " GREEN "%c" RESET "\n"
            "\t\t\tFifth    arg: " GREEN "%b" RESET "\n"
            "\t\t\tSixth    arg: " GREEN "%x" RESET "\n"
            "\t\t\tSeventh  arg: " GREEN "%c" RESET "\n"
            "\t\t\tEigth    arg: " GREEN "%b" RESET "\n\n", 0x34, 01234567, 0b100100100100, 65, 25, 0xDED, 33, 0b1010);

    // MyPrintf ("123456789101My printf ():1234\n"
    //           "123First    arg1234567: %x 123\n"
    //           "123Second   arg1234567: %o 123\n"
    //           "123Third    arg1234567: %b\n", 0x34, 01234567, 0b100100100);


    //MyPrintf ("%x %b %c %o %x %b %c %o\n", 0xDED4FACE, 0b1010, '=', 0777, 0xEDA, 0b1110011, '&', 0666);
    //MyPrintf ("%b I love my family %x\n", 0b100101001, 0xDED5FACE6EDA);

    printf ("\n\t\t\t\t" YELLOW "Std printf ():" RESET "\n"
              "\t\t\tFirst    arg: " GREEN "%x" RESET "\n"
              "\t\t\tSecond   arg: " GREEN "%o" RESET "\n"
              "\t\t\tThird    arg: " GREEN "%b" RESET "\n"
              "\t\t\tFourth   arg: " GREEN "%c" RESET "\n"
              "\t\t\tFifth    arg: " GREEN "%b" RESET "\n"
              "\t\t\tSixth    arg: " GREEN "%x" RESET "\n"
              "\t\t\tSeventh  arg: " GREEN "%c" RESET "\n"
              "\t\t\tEigth    arg: " GREEN "%b" RESET "\n\n", 0x34, 01234567, 0b100100100100, 65, 25, 0xDED, 33, 0b1010);

}

