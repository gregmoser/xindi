component accessors="true" extends="model.abstract.BaseGateway"{

	// ------------------------ PUBLIC METHODS ------------------------ //

	/**
	 * I delete a user
	 */		 	
	void function deleteUser( required User theUser ){
		delete( arguments.theUser );
	}

	/**
	 * I return a user matching an id
	 */		
	User function getUser( required numeric userid ){
		return get( "User", arguments.userid );
	}

	/**
	 * I return a user matching a username or email address and password
	 */	
	User function getUserByCredentials( required User theUser ){
		var User = ORMExecuteQuery( "from User where ( username=:username or email=:email ) and password=:password", { username=arguments.theUser.getUsername(), email=arguments.theUser.getEmail(), password=arguments.theUser.getPassword() }, true );
		if( IsNull( User ) ) User = new( "User" );
		return User;
	}

	/**
	 * I return a user matching a username or email address
	 */	
	User function getUserByEmailOrUsername( required User theUser ){
		var User = ORMExecuteQuery( "from User where username=:username or email=:email", { username=arguments.theUser.getUsername(), email=arguments.theUser.getEmail() }, true );
		if( IsNull( User ) ) User = new( "User" );
		return User;		
	}

	/**
	 * I return an array of users
	 */	
	array function getUsers(){
		return EntityLoad( "User", {}, "name" );
	}
	
	/**
	 * I return a new user
	 */		
	User function newUser(){
		return new( "User" );
	}
	
	/**
	 * I save a user
	 */	
	User function saveUser( required User theUser ){
		return save( arguments.theUser );
	}
	
}