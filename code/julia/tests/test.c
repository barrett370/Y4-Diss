#include <bezier.h>
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
// Inputs.
int num_nodes = 3;
int dimension = 2;
double nodes1[6] = { 0.0, 0.0, 2.0, 2.0, 5.0,4.0 };
//double nodes1[6] = { 0.0, 2.0, 5.0, 0.0,2.0,4.0};
double nodes2[6] = { 0.0, 5.0, 3.0,2.0, 6.0,0.0 };
//double nodes2[6] = { 0.0, 3.0, 6.0, 5.0,2.0,0.0};
int intersection_size = 9;
// Outputs.
double length = 2.0;
int error_val;

double *intersections ;
intersections =(double *) malloc(18);
int num_intersections = 0;
bool cooincident = false;
Status status = SUCCESS;

BEZ_curve_intersections(&num_nodes, nodes1, &num_nodes, nodes2, &intersection_size, intersections, &num_intersections, &cooincident, &status);
printf("num_intersections: %d\n", num_intersections);
int i;
for (i = 0; i < 17; i = i + 2) {
    printf("intersection %f, %f\n", intersections[i], intersections[i+1]);
}
}
