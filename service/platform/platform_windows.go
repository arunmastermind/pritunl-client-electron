package platform

import (
	"os"

	"github.com/dropbox/godropbox/errors"
	"github.com/hectane/go-acl"
	"github.com/pritunl/pritunl-client-electron/service/errortypes"
	"golang.org/x/sys/windows"
)

func MkdirSecure(pth string) (err error) {
	err = os.MkdirAll(pth, 0755)
	if err != nil {
		err = &errortypes.WriteError{
			errors.Wrap(err, "utils: Failed to create directory"),
		}
		return
	}

	_ = acl.Apply(
		pth,
		true,
		false,
		acl.GrantName(windows.GENERIC_ALL, "SYSTEM"),
		acl.GrantName(windows.GENERIC_ALL, "Administrators"),
	)

	return
}

func MkdirReadSecure(pth string) (err error) {
        err = os.MkdirAll(pth, 0755)
        if err != nil {
                err = &errortypes.WriteError{
                        errors.Wrap(err, "utils: Failed to create directory"),
                }
                return
        }

	_ = acl.Apply(
                pth,
                true,
                false,
                acl.GrantName(windows.GENERIC_ALL, "SYSTEM"),
                acl.GrantName(windows.GENERIC_ALL, "Administrators"),
                acl.GrantName(windows.GENERIC_READ, "Users"),
        )

	return
}
