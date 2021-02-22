/**
 *  WAGAMA4
 *  Author: patricktaillandier
 *  Description: add water diffusion dynamic (diffusion reflex  + flow action).
 */
model WAGAMA4

global {
	file intersection_file <- file('../includes/nodes_simple.shp');
	file env_file <- file('../includes/environment.shp');
	geometry shape <- envelope(env_file);

	init {
		create intersection from: intersection_file with: (id:read("ID"), id_next:read("ID_NEXT"), source:read("SOURCE"));
		ask intersection {
			next_intersection <- intersection first_with (each.id = id_next);
		}
		do water_input;

	}

	action water_input {
		ask intersection where (each.source = "Yes") {
			create water returns: water_created;
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
				do die;
			}
			ask world {
				do water_input;
			}

		} else {
			loop wAg over: waters {
				ask next_intersection {
					do accept_water(wAg);
				}

			}

		}

		waters <- [];
	}

}

species water {

	aspect default {
		draw circle(5) color: #blue;
	}

}

experiment with_interface type: gui {
	parameter 'GIS file of the nodes' var: intersection_file category: 'GIS';
	parameter 'GIS file of the environment' var: env_file category: 'GIS';

	user_command "Add water" {ask world {do water_input;}}


	output {
		display dynamic {
			species intersection aspect: network;
			species intersection aspect: circle;
			species water;
		}

	}

}