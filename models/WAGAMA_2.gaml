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
		// Create agents 'intersection' following a shapefile
		// with some parameters gathered in the shapefile
		create intersection from: intersection_file with: (id:read("ID"), id_next:read("ID_NEXT"), source:read("SOURCE"));
		
		// Foreach agent of type 'intersection'
		ask intersection {
			// Set value to specie's local variable 'next_intersection'
			// with first agent of type 'intersection' and with the local variable 'id' == current agent's 'id_next' value 
			next_intersection <- intersection first_with (each.id = id_next);
		}
	}
}


species intersection {
	float radius <- 2.0;
	rgb color <- #white;
	// Add more variable in the specie
	string id;
	string id_next;
	string source;
	// Add a variable of custom type
	intersection next_intersection;
		
	aspect circle {
		draw circle(radius) color: color border: #black;
	}
	
	// Add a second aspect in the specie
	aspect network {
		if (next_intersection != nil) {
			// Draw line in between agent's location and chained agent's location
			draw line([location, next_intersection.location]) color: #blue;
		}
	}
}


experiment with_interface type: gui {
	parameter 'GIS file of the nodes' var: intersection_file category: 'GIS';
	parameter 'GIS file of the environment' var: env_file category: 'GIS';
	output {
		display dynamic {
			species intersection aspect: circle;
			// Draw lines in between agents
			species intersection aspect: network;
		}
	}
}