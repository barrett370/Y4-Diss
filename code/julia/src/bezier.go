package main

import (
	"fmt"
)

type BezierCurve []Point

type Point struct {
    x float64
	y float64
}
func Times(a float64, b Point) Point{
	return Point{x: b.x * a,y: b.y*a}
}
func Add(a Point, b Point) Point {
    return Point{x: b.x + a.x,y: b.y + a.y}
}

func (curve BezierCurve) f(t float64) (Point){
	switch {
    case len(curve) == 1:
		return curve[0]
	default:
		b1 := BezierCurve(curve[1:len(curve)-1])
		b2 := BezierCurve(curve[2:])
		return Add(Times((1-t) , b1.f(t)) , Times(t,b2.f(t)))
	}
}

func bezInt(B1 BezierCurve, B2 BezierCurve, rdepth int32) bool {
	if rdepth + 1 > 10{
		return false
	}
	e := 0.7
	if len()
}


func main() {
	test_curve := BezierCurve([]Point{{x:0,y:0},{x:3,y:4}, {x:4,y:2}})
	fmt.Printf("test_curve(2) %v", test_curve.f(0.2))
}
