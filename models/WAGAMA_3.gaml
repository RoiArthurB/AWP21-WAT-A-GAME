/**
 *  WAGAMA3
 *  Author: patricktaillandier
 *  Description: new species definition (water); action definition (water_input and accept_water); button definition
 */

model WAGAMA3
 
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
	
	// Add global action
	action water_input {
		// Foreach agent of type intersection with attribute 'source' == "Yes"
		ask intersection where (each.source = "Yes" ) {
			// Create new agent of type 'water' called 'water_created'
			create water returns: water_created;
			// Call intersection's action called 'accept_water' with arguments
			do accept_water water_input: first(water_created);
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
	// Add dynamic list of custom type
	list<water> waters;
		
	aspect circle {
		draw circle(radius) color: color border: #black;
	}
	
	aspect network {
		if (next_intersection != nil) {
			draw line([location, next_intersection.location]) color: #blue;
		}
	}
	
	// Add action with parameter
	action accept_water(water water_input) {
		// Add agent 'water_input' in local list 'waters'
		waters << water_input;
		// Move agent 'water_input' to intersection location
		water_input.location <- location;
	}
}

// Add new specie called 'water'
species water {
	// Define water's aspect
	// GTK: 'default' aspect's name will be 
	//automatically called if nothing else is set in the display
	aspect default{
		draw circle(5) color: #blue;
	}	
}


experiment with_interface type: gui {
	parameter 'GIS file of the nodes' var: intersection_file category: 'GIS';
	parameter 'GIS file of the environment' var: env_file category: 'GIS';
	// Define user_command calling the global action 'water_input'
	user_command "Add water" {ask world {do water_input;}}
	
	output {
		display dynamic {
			species intersection aspect: network;
			species intersection aspect: circle;
			// Display agents 'water' with default aspect
			species water;
		}
	}
}

