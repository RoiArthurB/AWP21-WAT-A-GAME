/**
 *  WAGAMA2
 *  Author: patricktaillandier
 *  Description: attribut reading from GIS data; more complex agent aspect ; use of the function facet
 */

model WAGAMA2
 
global {
	
	file intersection_file <- file('../includes/nodes_simple.shp'); 
	file env_file <- file('../includes/environment.shp');
	
	geometry shape <- envelope(env_file);
	
	init {
		create intersection from: intersection_file with: (id:read("ID"), id_next:read("ID_NEXT"), source:read("SOURCE"));
		ask intersection {
			next_intersection <- intersection first_with (each.id = id_next);
		}
	}
}


species intersection {
	float radius <- 2.0;
	rgb color <- #white;
	string id;
	string id_next;
	string source;
	intersection next_intersection;
		
	aspect circle {
		draw circle(radius) color: color border: #black;
	}
	
	aspect network {
		if (next_intersection != nil) {
			draw line([location, next_intersection.location]) color: #blue;
		}
	}
}


experiment with_interface type: gui {
	parameter 'GIS file of the nodes' var: intersection_file category: 'GIS';
	parameter 'GIS file of the environment' var: env_file category: 'GIS';
	output {
		display dynamic {
			species intersection aspect: network;
			species intersection aspect: circle;
		}
	}
}