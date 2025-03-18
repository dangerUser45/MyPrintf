extern "C" void MyPrintf(const char* format, ...);

int main ()
{
    MyPrintf ("%c%c%c%c\n", '1', '2', '3', '4');
}
