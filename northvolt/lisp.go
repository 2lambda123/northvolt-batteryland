package northvolt

import (
	"context"
	"fmt"

	"github.com/deosjr/whistle/lisp"
	"github.com/northvolt/go-service-digitaltwin/digitaltwin"
	"github.com/northvolt/go-service-digitaltwin/digitaltwin/digitaltwinhttp"
	"github.com/northvolt/go-service/localrunner"
)

// caching northvolt api calls so we dont overwhelm it
// pages run their script _each frame_ right now
// map from apiendpoint to input to data
var cache = map[string]map[lisp.SExpression]lisp.SExpression{}

var dt digitaltwin.Service

// wrapper around nv service calls

func Load(env *lisp.Env) {
	r := localrunner.NewLocalRunner()
	dt = digitaltwinhttp.NewClient(r.FixedInstancer("/digitaltwin")).WithReqModifier(r.AuthorizeHeader())
	cache["identity"] = map[lisp.SExpression]lisp.SExpression{}

	env.AddBuiltin("dt:identity", dtIdentity)
}

func dtIdentity(args []lisp.SExpression) (lisp.SExpression, error) {
	ctx := context.Background()
	arg0 := args[0]
	prev, ok := cache["identity"][arg0]
	if ok {
		return prev, nil
	}

	nvid := arg0.AsPrimitive().(string)
	fmt.Printf("calling digitaltwin identity %s\n", nvid)
	identity, err := dt.Identity(ctx, nvid)
	if err != nil {
		return nil, err
	}
	result := lisp.NewPrimitive(identity)
	cache["identity"][arg0] = result
	return result, nil
}
