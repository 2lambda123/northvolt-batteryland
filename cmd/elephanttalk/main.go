package main

import (
	_ "embed"
	//"fmt"
	"log"

	"github.com/northvolt/batteryland/talk"
)

//go:embed test.lisp
var testpage string

func main() {
	log.SetFlags(0)
	log.Print("Starting...")

	// instead of using all coloured dots to identify pages, only use the corner dots
	talk.UseSimplifiedIDs()

	//page1
	talk.AddPageFromShorthand("ygybr", "brgry", "gbgyg", "bgryy", `(claim this 'modifies 'processdata)`)

	//page2
	talk.AddPageFromShorthand("yggyg", "rgyrb", "bybbg", "brgrg", `(claim this 'cell 'testid)`)

	//page that always counts as recognised but doesnt have to be present physically
	talk.AddBackgroundPage(testpage)

	talk.Run()
}
