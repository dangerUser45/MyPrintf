extern "C" void MyPrintf(const char* format, ...);

int main ()
{
       MyPrintf ("Mathematical %s: %o + (%d) + %b - %x %c %d\n",
                 "facts", 04, -2, 0b100, 0x50,'=', 52);
}
