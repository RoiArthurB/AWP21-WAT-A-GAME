/**
 *  WAGAMA16
 *  Author: patricktaillandier
 *  Description: new actions for the owner agents
 */

model WAGAMA16


global {
	
	file intersection_file <- file('../includes/nodes.shp');
	file env_file <- file('../includes/environment.shp');
	file activities_file <- file('../includes/activities.shp');
	file owners_data <- csv_file('../includes/owners_data.csv',";", true);
	file activity_type_data <- csv_file('../includes/activity_type_data.csv',";",true);
	
	string result_file <- 'results.csv';
	
	geometry shape <- envelope(env_file);
	
		
	int total_water_quantity -> {length(water_unit as list)};
	int clean_water_quantity -> {(water_unit as list) count (!each.polluted)};
	int polluted_water_quantity -> {(water_unit as list) count (each.polluted)};
	float mean_money -> {owner mean_of (each.money)};
	int max_money -> {owner max_of (each.money)};
	int min_money -> {owner min_of (each.money)};
	
	int input_water_quantity_north <- 20;
	int input_water_quantity_south <- 20;
	int output_water_quantity_real;
	int output_clean_water_quantity_real;
	int output_polluted_water_quantity_real;
	int output_water_quantity_wished <- 5;
	
	
	float cleanness_rate_objective <- 0.7;
	int output_water_quantity_objective <- 5;
	
	administrator the_administrator;
	
	init {
		create administrator {
			the_administrator <- self;
		}
		
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
		create activity_type from: activity_type_data with: (name:get("activity_type"), clean_water_input:int(get("clean_water_input")),
			polluted_water_input:int(get("polluted_water_input")),money_cost:int(get("money_cost")),clean_water_output:int(get("clean_water_output")),
			polluted_water_output:int(get("polluted_water_output")),money_earned:int(get("money_earned")),excessive_water:bool(get("excessive_water")),
			excessive_pollution:bool(get("excessive_pollution")),green_activity:bool(get("green_activity")),color:rgb(get("color")));
	
		create activity from: activities_file with: (id:read("ID"), input_id:read("INPUT"), output_id:read("OUTPUT"), type_name:read("TYPE"));
		ask activity {
			input_node <- intersection first_with (each.id = input_id);
			output_node <- intersection first_with (each.id = output_id);
			type <- activity_type first_with (each.name = type_name) ;
		}
		do load_owners_data;
		
		do water_input;
		save "input_water_quantity_north,input_water_quantity_south,output_water_quantity_real,output_clean_water_quantity_real,output_polluted_water_quantity_real,mean_money,max_money,min_money" type: text to: result_file;
		
	}
	
	action water_input {
		ask intersection where (each.source = "Yes") {
			create water returns: water_created {
				int  input_water_quantity <- (myself.id = '1') ? input_water_quantity_north : input_water_quantity_south ;
				
				create water_unit number: input_water_quantity{
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
	
	
	action load_owners_data {
		matrix owner_matrix <- matrix(owners_data);
		loop i from: 0 to: owner_matrix.rows - 1 {
			string id_activity <- owner_matrix[0,i];
			string id_owner <- owner_matrix[1,i];
			activity current_activity <- activity first_with (each.id = id_activity);
			if (current_activity != nil ) {
				owner current_owner <- owner first_with (each.id = id_owner);
				if (current_owner = nil) {
					create owner returns: owner_created with: (id : id_owner){
						current_owner <- self;
					}
				}
				current_activity.my_owner <- current_owner;
				current_owner.my_activities << current_activity ; 	
			}	
		}	
	}
	
	action save_outputs {
		save [input_water_quantity_north, input_water_quantity_south, output_water_quantity_real, output_clean_water_quantity_real, 
			output_polluted_water_quantity_real,mean_money,max_money,min_money] rewrite: false type: csv to: result_file;
	}
	
	action repair_activity {
		activity act <- first(activity overlapping #user_location);
		if (act != nil) {
			ask act {
				do repair;
			}
		}
	}
	
	action change_activity {
		activity act <- first(activity overlapping #user_location);
		if (act != nil) {
			ask act {
				 map input_values <- user_input([choose("New activity type", string,type.name, activity_type collect each.name)]);
     			activity_type act_type <- activity_type first_with (each.name =  string(input_values at "New activity type"));
				do change_type(act_type);
			}
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
			output_water_quantity_real <- 0;
			output_clean_water_quantity_real <- 0;
			output_polluted_water_quantity_real <- 0;
			
			ask waters {			
				output_water_quantity_real <- output_water_quantity_real +  quantity;
				output_clean_water_quantity_real <- output_clean_water_quantity_real + quantity_clean ;
				output_polluted_water_quantity_real <- output_polluted_water_quantity_real + quantity_polluted;
					
				ask water_units {
					do die;
				}
				do die;
				
			}
			ask world {
				do save_outputs;
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
	owner my_owner;
	string type_name;
		
		
	action take_water (water water_in){
		int wished_quantity <- type.clean_water_input + type.polluted_water_input;
		int quantity<- min (water_in.quantity, wished_quantity);
		list<water_unit> water_unit_taken <- quantity among  water_in.water_units;
		water_in.water_units <- water_in.water_units - water_unit_taken;
		
		int money_lost <- min (my_owner.money, type.money_cost);
		my_owner.money <- my_owner.money - money_lost;
			
		dysfunction <- (quantity < wished_quantity) or 
			((water_unit_taken count (each.polluted)) > type.polluted_water_input) or
			(money_lost < type.money_cost);
		
		if (!dysfunction) {
			 my_owner.money <- my_owner.money + type.money_earned;
		}
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
	
	action repair{
		if (dysfunction) and (my_owner.money >= type.money_cost) {
			my_owner.money <- my_owner.money - type.money_cost;
			dysfunction <- false;
		}
	}
		
	action change_type (activity_type new_type){
		int change_cost <- type.money_cost + new_type.money_cost;
		if (my_owner.money  >= change_cost) {
			my_owner.money  <- my_owner.money  - change_cost;
			type <- new_type;
		}
	}
		
		
	user_command repair_activity{
		do repair;
	}
	
	user_command change_activity_type{
		 map input_values <- user_input([choose("New activity type", string,type.name, activity_type collect each.name)]);
     	activity_type act_type <- activity_type first_with (each.name =  string(input_values at "New activity type"));
		do change_type(act_type);
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
	
	aspect owners{
		draw line([location, input_node.location]) color: #green;
		draw line([location, output_node.location]) color: #red;
		draw shape color: my_owner.color;
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
	int money_earned <- 3;
	int money_cost <- 2;
}

species owner {
	string id;
	list<activity> my_activities;
	int money <- 10;
	rgb color <- rnd_color(255);
}	

species administrator {
	int pollution_tax <- 2;
	int water_tax <- 2;
	int ecological_bonus <- 2;
	bool decision_time <- false; 
	
	action tax_polluters {
		ask (activity where (each.type.excessive_pollution)) {
			int to_pay <- min(myself.pollution_tax, my_owner.money);
			my_owner.money <- my_owner.money - to_pay;
		}
	}
	
	action tax_water_users {
		ask (activity where (each.type.excessive_water)) {
			int to_pay <- min(myself.water_tax, my_owner.money);
			my_owner.money <- my_owner.money - to_pay;
		}
	}
		
	action favor_green_activities {
		ask (activity where (each.type.green_activity)) {
			my_owner.money <- my_owner.money + myself.ecological_bonus;
		}
	}
		
	reflex take_measures when: decision_time {
		float cleanness_rate <- output_water_quantity_real > 0 ? output_clean_water_quantity_real  / output_water_quantity_real : 1;
		string message_to_write <-"**********************\nTotal quantity of water : " + output_water_quantity_real + "\nCleanness rate : " + cleanness_rate;
		if (output_water_quantity_real  < output_water_quantity_objective)
		{
			do tax_water_users;
			message_to_write <- message_to_write + "\nMeasure taken : tax the activities that consumn too much water";
		}
		if (cleanness_rate < cleanness_rate_objective)
		{
			if flip(0.5) {
				do tax_polluters;	
				message_to_write <- message_to_write + "\nMeasure taken : tax the activities that pollute too much";
			} else {
				do favor_green_activities;	
				message_to_write <- message_to_write + "\nMesure taken : give a bonus to green activities";
			}
		}
		write message_to_write;
		ask world {
			do save_outputs;	
		}
		decision_time <- false;
	}
} 

experiment with_interface type: gui {
	parameter 'GIS file of the nodes' var: intersection_file category: 'GIS';
	parameter 'GIS file of the environment' var: env_file category: 'GIS';
	parameter 'GIS file of the activities' var: activities_file category: 'GIS';
	parameter 'Quantity of input water North' var: input_water_quantity_north category: 'Water';
	parameter 'Quantity of input water South' var: input_water_quantity_south category: 'Water';
	parameter 'Owners data' var: owners_data category: 'Owners';
	parameter 'Activity type data' var: activity_type_data category: 'Activities';
	
	parameter 'Objective concerning the output water quantity' var: output_water_quantity_objective category: 'Water';
	parameter 'Objective concerning the output water quality (cleanness rate)' var: cleanness_rate_objective category: 'Water';
	
	user_command "Add water" {ask world {do water_input;}}

	output {
		monitor 'Water quantity' value: length(water_unit) ;
		
		display dynamic {
			event mouse_down action: repair_activity;
			
			species intersection aspect: network;
			species intersection aspect: circle;
			species activity ;
			species water aspect: quantity_quality;
		}
		display activity_type {
			event mouse_down action: change_activity;
			
			species intersection aspect: network;
			species intersection aspect: circle;
			species activity aspect: activity_type;
		}
		display owners {
			species intersection aspect: network;
			species intersection aspect: circle;
			species activity aspect: owners;
		}
		
		display charts { 
			chart "Water quantity" type: series background: rgb('white') size: {1,0.5} position: {0, 0} {
				data "Total water quantity" value: total_water_quantity color: rgb('blue') ;
				data "Clean water quantity" value: clean_water_quantity color: rgb('green') ;
				data "Polluted water quantity" value: polluted_water_quantity color: rgb('red') ;
			}
			chart "Money of the owners" type: series background: rgb('white') size: {1,0.5} position: {0, 0.5} {
				data "Mean money" value: mean_money color: rgb('black') ;
				data "Min money" value: min_money  color: rgb('red') ;
				data "Max money" value: max_money  color: rgb('green') ;
			}	
		}
	}

}
	

	
experiment calibration type: batch repeat: 10 keep_seed: true until: ( time > 15 ) {
	parameter 'Quantity of input water North' var: input_water_quantity_north min: 10 max: 30 step: 1;
	parameter 'Quantity of input water South' var: input_water_quantity_south min: 10 max: 30 step: 1 ;
	method tabu minimize: abs(output_water_quantity_real - output_water_quantity_wished) iter_max: 50 tabu_list_size: 5;
	
	reflex show_results{
		write sample(input_water_quantity_north) + " " + sample(input_water_quantity_south) +" error: " + simulations mean_of (abs(each.output_water_quantity_real - each.output_water_quantity_wished)) ;
	}
}
	
	
	