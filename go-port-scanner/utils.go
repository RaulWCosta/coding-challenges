package main

import (
	"runtime"

	"golang.org/x/sys/unix"
)

// https://github.com/tevino/tcp-shaker/blob/1af45280385ed121d51cf8ad1d01c629610ea2c2/socket.go#L41
func connect(fd int, addr unix.Sockaddr) (success bool, err error) {
	switch serr := unix.Connect(fd, addr); serr {
	case unix.EALREADY, unix.EINPROGRESS, unix.EINTR:
		// Connection could not be made immediately but asynchronously.
		success = false
		err = nil
	case nil, unix.EISCONN:
		// The specified socket is already connected.
		success = true
		err = nil
	case unix.EINVAL:
		// On Solaris we can see EINVAL if the socket has
		// already been accepted and closed by the server.
		// Treat this as a successful connection--writes to
		// the socket will see EOF.  For details and a test
		// case in C see https://golang.org/issue/6828.
		if runtime.GOOS == "solaris" {
			success = true
			err = nil
		} else {
			// error must be reported
			success = false
			err = serr
		}
	default:
		// Connect error.
		success = false
		err = serr
	}
	return success, err
}
