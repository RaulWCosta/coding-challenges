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

func validate_args(host string, port int) error {
	if host == "" {
		return fmt.Errorf("`--host` not set")
	}
	if port != 0 {
		if port < 1 || port >= pow_2_16 {
			return fmt.Errorf("`--port` value must be between 1 and %d", pow_2_16-1)
		}

	}
	return nil
}

func scan_port(host string, port int, timeout int, wg *sync.WaitGroup, msgChan chan<- Msg) {
	fmt.Printf("Scanning host %q port %d\n", host, port)
	defer wg.Done()

	address := fmt.Sprintf("%s:%d", host, port)
	to_duration, err := time.ParseDuration(fmt.Sprintf("%dms", timeout))
	if err != nil {
		msgChan <- Msg{port, false}
		return
	}
	conn, err := net.DialTimeout("tcp", address, to_duration)
	if err != nil {
		// fmt.Printf("%d", port)
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

func print_open_ports(port int, wg *sync.WaitGroup, msgChan <-chan Msg) {
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
	var host string
	var port int
	var timeout int

	app := &cli.App{
		Name:        "myps",
		Description: "My Port Scanner",
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:        "host",
				Aliases:     []string{"h"},
				Usage:       "Host",
				Value:       "localhost",
				Destination: &host,
			},
			&cli.IntFlag{
				Name:    "port",
				Aliases: []string{"p"},
				Usage:   "Port",
				// Value: 8000,
				DefaultText: "All ports",
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

			err := validate_args(host, port)
			if err != nil {
				fmt.Printf("Error: " + err.Error())
				return nil
			}
			if port == 0 {
				wg.Add(pow_2_16 - 1)
				for i := 1; i < pow_2_16; i++ {
					go scan_port(host, i, timeout, &wg, msgChan)
				}
			} else {
				wg.Add(1)
				scan_port(host, port, timeout, &wg, msgChan)
			}
			print_open_ports(port, &wg, msgChan)

			return nil
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}
