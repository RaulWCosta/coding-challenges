package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"sync"
	"time"

	"github.com/urfave/cli/v2" // imports as package "cli"
)

const pow_2_16 = 65536

type Msg struct {
	int
	bool
}

func scanPort(host string, port int, timeout int, wg *sync.WaitGroup, msgChan chan<- Msg) {
	fmt.Printf("Scanning host %q port %d\n", host, port)
	defer wg.Done()

	address := net.JoinHostPort(host, fmt.Sprintf("%d", port))
	to_duration, err := time.ParseDuration(fmt.Sprintf("%dms", timeout))
	if err != nil {
		msgChan <- Msg{port, false}
		return
	}
	conn, err := net.DialTimeout("tcp", address, to_duration)
	if err != nil {
		msgChan <- Msg{port, false}
		return
	}
	defer conn.Close()

	n, err := conn.Write([]byte("0"))
	if n == 0 || err != nil {
		msgChan <- Msg{port, false}
		return
	}
	msgChan <- Msg{port, true}
}

func printOpenPorts(port int, wg *sync.WaitGroup, msgChan <-chan Msg) {
	wg.Wait()

	if port == 0 {
		for i := 1; i < pow_2_16; i++ {
			pair := <-msgChan
			if pair.bool {
				fmt.Printf("\nPort: %d is open\n", pair.int)
			}
		}
	} else {
		pair := <-msgChan
		if pair.bool {
			fmt.Printf("\nPort: %d is open\n", pair.int)
		}
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
			var wg sync.WaitGroup
			msgChan := make(chan Msg, pow_2_16)

			if port == 0 {
				// scan all ports
				for _, host := range hosts {
					wg.Add(pow_2_16 - 1)
					for i := 1; i < pow_2_16; i++ {
						go scanPort(host, i, timeout, &wg, msgChan)
					}
				}
			} else {
				for _, host := range hosts {
					wg.Add(1)
					go scanPort(host, port, timeout, &wg, msgChan)
				}
			}
			printOpenPorts(port, &wg, msgChan)

			return nil
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}
