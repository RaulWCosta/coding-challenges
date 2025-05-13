package main

import (
	"testing"
)

// TestHelloName calls greetings.Hello with a name, checking
// for a valid return value.
func TestResolveHost(t *testing.T) {
	tests := []struct {
		host     string
		expected []string
	}{
		{"192 .168.1.1", []string{"192 .168.1.1"}},
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
