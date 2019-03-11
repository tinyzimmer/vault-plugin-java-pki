package pki

import (
	"strings"
	"unicode"
)

func normalizeSerial(serial string) string {
	return strings.Replace(strings.ToLower(serial), ":", "-", -1)
}

func containsUppercase(input string) bool {
	for _, rune := range input {
		if unicode.IsUpper(rune) {
			return true
		}
	}
	return false
}
