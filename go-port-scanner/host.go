package main

import (
	"fmt"
	"strings"
)

func resolveHost(host string) []string {
	// check if ip has wildcard, if yes, return all matching ips lazily
	if strings.Contains(host, "*") {
		ips := []string{}
		for i := 0; i < 256; i++ {
			ips = append(ips, strings.Replace(host, "*", fmt.Sprintf("%d", i), 1))
		}
		return ips
	}
	return []string{host}
}

func resolveHosts(hosts string) []string {
	splitted_hosts := strings.Split(hosts, ",")
	if len(splitted_hosts) == 1 {
		splitted_hosts = []string{splitted_hosts[0]}
	}
	var resolved_hosts []string

	for _, host := range splitted_hosts {
		host = strings.TrimSpace(host)
		resolved_hosts = append(resolved_hosts, resolveHost(host)...)
	}
	return resolved_hosts
}
