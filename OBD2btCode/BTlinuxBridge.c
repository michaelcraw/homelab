#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <bluetooth/bluetooth.h>
#include <bluetooth/rfcomm.h>

int main() {
    int sock;
    struct sockaddr_rc addr = {0};
    char dest[18] = "01:23:45:67:89:BA"; // ELM327 MAC
    char buf[1024] = {0};

    // Create Bluetooth socket
    sock = socket(AF_BLUETOOTH, SOCK_STREAM, BTPROTO_RFCOMM);

    // Set target address and channel
    addr.rc_family = AF_BLUETOOTH;
    addr.rc_channel = 1;
    str2ba(dest, &addr.rc_bdaddr);

    // Connect
    connect(sock, (struct sockaddr *)&addr, sizeof(addr));

    // Send ATI command
    write(sock, "ATI\r", 4);

    // Read response
    read(sock, buf, sizeof(buf));
    printf("Response: %s\n", buf);

    close(sock);
    return 0;
}