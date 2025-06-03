package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"syscall"

	"github.com/urfave/cli/v2" // imports as package "cli"
	"golang.org/x/sys/unix"
)

const pow_2_16 = 65536

type Msg struct {
	int
	bool
}

func scanPort(host string, port int, msgChan chan<- Msg) {
	address := net.JoinHostPort(host, fmt.Sprintf("%d", port))
	tAddr, err := net.ResolveTCPAddr("tcp", address)
	if err != nil {
		log.Fatalf("Can not resolve '%s': %s", address, err)
	}

	fd, err := syscall.Socket(syscall.AF_INET, syscall.SOCK_STREAM, 0)
	if err != nil {
		msgChan <- Msg{port, false}
		return
	}
	defer func() {
		if cerr := unix.Close(fd); cerr != nil {
			log.Printf("Error closing socket: %s", cerr)
		}
	}()

	var sAddr unix.Sockaddr

	if ip := tAddr.IP.To4(); ip != nil {
		var addr4 [net.IPv4len]byte
		copy(addr4[:], ip)
		sAddr = &unix.SockaddrInet4{Port: tAddr.Port, Addr: addr4}
	}

	if success, err := connect(fd, sAddr); err != nil {
		msgChan <- Msg{port, false}
		return
	} else if success {
		msgChan <- Msg{port, true}
		return
	}
	msgChan <- Msg{port, false} // Ensure we always send a message to avoid deadlock
}

func printOpenPort(msgChan <-chan Msg) {
	pair := <-msgChan
	if pair.bool {
		fmt.Printf("\nPort: %d is open\n", pair.int)
	}
}

func main() {
	var hosts []string
	var port int
	var timeout int

	app := &cli.App{
		Name:        "myps",
		Description: "My Port Scanner",
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:     "hosts",
				Usage:    "Hosts to scan",
				Required: true,
				Action: func(cCtx *cli.Context, input string) error {
					hosts = resolveHosts(input)
					fmt.Print(hosts)
					return nil
				},
			},
			&cli.IntFlag{
				Name:        "port",
				Usage:       "Port",
				DefaultText: "All ports",
				Value:       0,
				Destination: &port,
			},
			&cli.IntFlag{
				Name:        "timeout (ms)",
				Aliases:     []string{"t"},
				Value:       100,
				Destination: &timeout,
			},
			cli.HelpFlag,
		},
		Action: func(cCtx *cli.Context) error {
			msgChan := make(chan Msg, 100)

			for _, host := range hosts {
				if port == 0 {
					for i := 1; i < pow_2_16; i++ {
						go scanPort(host, i, msgChan)
						go printOpenPort(msgChan)
					}
				} else {
					go scanPort(host, port, msgChan)
					go printOpenPort(msgChan) // TODO fix, this is not printing
				}
			}

			return nil
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}
