package main

import (
	"strconv"
	"testing"
)

func TestResolveHost(t *testing.T) {
	tests := []struct {
		host     string
		expected []string
	}{
		{"192.168.1.1", []string{"192.168.1.1"}},
		{"localhost", []string{"localhost"}},
	}
	for _, test := range tests {
		actual := resolveHost(test.host)
		if len(actual) != len(test.expected) {
			t.Errorf("resolveHost(%q) = %v; expected %v", test.host, actual, test.expected)
		} else {
			for i, v := range actual {
				if v != test.expected[i] {
					t.Errorf("resolveHost(%q)[%d] = %q; expected %q", test.host, i, v, test.expected[i])
				}
			}
		}
	}
}

func TestResolveHostCIDR(t *testing.T) {

	host := "192.168.1.*"
	expected := []string{}
	for i := 0; i < 256; i++ {
		expected = append(expected, "192.168.1."+strconv.Itoa(i))
	}
	actual := resolveHost(host)
	if len(actual) != len(expected) {
		t.Errorf("resolveHost(%q) = %v; expected %v", host, actual, expected)
	} else {
		for i, v := range actual {
			if v != expected[i] {
				t.Errorf("resolveHost(%q)[%d] = %q; expected %q", host, i, v, expected[i])
			}
		}
	}
}
