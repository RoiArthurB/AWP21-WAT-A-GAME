/**
 *  WAGAMA9
 *  Author: patricktaillandier
 *  Description: definition of the activity_type species, definition of new actions (take_water reject_water) for the activity agents
 */

model WAGAMA9

global {
	file intersection_file <- file('../includes/nodes.shp');
	file env_file <- file('../includes/environment.shp');
	file activities_file <- file('../includes/activities.shp');
	
	geometry shape <- envelope(env_file);
	int input_water_quantity <- 20;
	
	init {
		create intersection from: intersection_file with: (id:read("ID"), id_next:read("ID_NEXT"), source:read("SOURCE"));
		ask intersection {
			next_intersection <- intersection first_with (each.id = id_next);
		}
		ask intersection {
			if (source = "Yes" ) {
				nb_inputs <- 1;
			} else {
				nb_inputs <- intersection count (each.next_intersection = self);
			}
		}
		create activity_type returns: activity_type_created;
		
		create activity from: activities_file with: (id:read("ID"), input_id:read("INPUT"), output_id:read("OUTPUT"));
		ask activity {
			input_node <- intersection first_with (each.id = input_id);
			output_node <- intersection first_with (each.id = output_id);
			type <- first(activity_type_created);
		}
		
		do water_input;
	}
	
	action water_input {
		ask intersection where (each.source = "Yes") {
			create water returns: water_created {
				create water_unit number: input_water_quantity {
					myself.water_units << self;
				}
			}
			do accept_water water_input: first(water_created);
		}
	}
	
	reflex diffusion {
		ask intersection where (!(empty(each.waters))) {
			do flow;
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
	list<water> waters;
	int nb_inputs;

	aspect circle {
		draw circle(radius) color: color border: #black;
	}

	aspect network {
		if (next_intersection != nil) {
			draw line([location, next_intersection.location]) color: #blue;
		}

	}

	action accept_water (water water_input) {
		waters << water_input;
		water_input.location <- location;
	}

	action flow {
		if (next_intersection = nil) {
			ask waters {				
				ask water_units {
					do die;
				}
				do die;
			}
			ask world {
				do water_input;
			}

		} else {
			do water_merge;
			
			loop wAg over: waters {
				ask (activity where (each.input_node = self and !(each.dysfunction))) {
					do take_water water_in: wAg;
				}
				ask (activity where (each.output_node = self and !(each.dysfunction))) {
					do reject_water water_out: wAg;
				}
				ask next_intersection {
					do accept_water(wAg);
				}
			}
		}
		waters <- [];
	}
	
	action water_merge {
		if (length(waters) > 1) {
			create water with: (water_units: waters accumulate each.water_units) returns: water_created;
			ask waters {
				do die;
			}
			waters <- water_created;
		} 
	} 

}

		
species water {
	list<water_unit> water_units;
	int quantity -> {length(water_units)};
	int quantity_polluted -> {water_units count (each.polluted)};
	int quantity_clean -> {water_units count (!each.polluted)};
		
	aspect default {
		draw circle(5) color: #blue;
	}
	
	aspect quantity_quality{
		draw circle(quantity / 4) 
			color: rgb([255 * quantity_polluted / quantity, 0, 255 * quantity_clean / quantity]);
	}

}

species water_unit {
	bool polluted <- false;
}
	
species activity {
	string id;
	string input_id;
	string output_id;
	intersection input_node;
	intersection output_node;
	rgb color -> {dysfunction ? #red : #green};
	bool dysfunction <- false;
	activity_type type;
		
		
	action take_water (water water_in){
		int wished_quantity <- type.clean_water_input + type.polluted_water_input;
		int quantity<- min (water_in.quantity, wished_quantity);
		list<water_unit> water_unit_taken <- quantity among  water_in.water_units;
		water_in.water_units <- water_in.water_units - water_unit_taken;
		dysfunction <- (quantity < wished_quantity) or ((water_unit_taken count (each.polluted)) > type.polluted_water_input);
		ask water_unit_taken {
			do die;
		}
	}
		
	action reject_water (water water_out) {
		create water_unit number: type.clean_water_output returns: wu_clean;
		create water_unit number: type.polluted_water_output returns: wu_polluted {
			polluted <- true;
		}
		water_out.water_units <- water_out.water_units + list(wu_clean) + list(wu_polluted);	
	}
		

	aspect default{
		draw line([location, input_node.location]) color: #green;
		draw line([location, output_node.location]) color: #red;
		draw shape color: color border: #black;
	}
	
	aspect activity_type{
		draw line([location, input_node.location]) color: #green;
		draw line([location, output_node.location]) color: #red;
		draw shape color: type.color border: #black;
		draw name + " : " + type.name size: 2 color: #black;
	}
}

	
	
species activity_type {
	int clean_water_input <- 3;
	int polluted_water_input <- 1;
	int clean_water_output <- 0;
	int polluted_water_output <- 2;
	bool excessive_water <- false;
	bool excessive_pollution <- false;
	bool green_activity <- false;
	rgb color <- #yellow;
	
}

experiment with_interface type: gui {
	parameter 'GIS file of the nodes' var: intersection_file category: 'GIS';
	parameter 'GIS file of the environment' var: env_file category: 'GIS';
	parameter 'GIS file of the activities' var: activities_file category: 'GIS';
	parameter 'Quantity of input water' var: input_water_quantity category: 'Water';
	
	user_command "Add water" {ask world {do water_input;}}

	

	output {
		monitor 'Water quantity' value: length(water_unit) ;
		
		display dynamic {
			species intersection aspect: network;
			species intersection aspect: circle;
			species activity ;
			species water aspect: quantity_quality;
		}
		display activity_type {
			species intersection aspect: network;
			species intersection aspect: circle;
			species activity aspect: activity_type;
		}

	}

}