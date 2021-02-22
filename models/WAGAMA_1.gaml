/**
 *  WAGAMA1
 *  Author: Patrick Taillandier
 *  Description: model structure definition; species definition (node agents); display definition; parameter definition; agent creation from GIS data
 */

model WAGAMA1
 
global {
	
	file intersection_file <- file('../includes/nodes_simple.shp'); 
	file env_file <- file('../includes/environment.shp');
	
	geometry shape <- envelope(env_file);
	init {
		create intersection from: intersection_file;
	}
}

species intersection {
	float radius <- 2.0;
	rgb color <- #white;
		
	aspect circle {
		draw circle(radius) color: color border: #black;
	}
}


experiment with_interface type: gui {
	parameter 'GIS file of the nodes' var: intersection_file category: 'GIS';
	parameter 'GIS file of the environment' var: env_file category: 'GIS';
	output {
		display dynamic {
			species intersection aspect: circle;
		}
	}
}