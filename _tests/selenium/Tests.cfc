/*
	Xindi - http://www.getxindi.com/
	
	Copyright (c) 2012, Simon Bingham
	
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
	modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
	is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
	IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/* run these tests in your browser at http://localhost/xindi/_tests/selenium/Tests.cfc?method=runTestRemote */

// component extends mxunit.framework.TestCase
component extends="mxunit.framework.TestCase"{

	// run once before all tests
	function beforeTests() {
		// set url of Xindi installation
		browserURL = "http://localhost:8888/xindi";
		// set browser to be used for testing
		browserCommand = "*firefox";
		// create a new instance of CFSelenium
	   	selenium = createobject( "component", "CFSelenium.selenium" ).init();
	   	// assertion used by testStartAndStopBrowser test
	   	assertFalse( Len( selenium.getSessionId() ) );
		// start Selenium server
		selenium.start( browserUrl, browserCommand );
		// assertion used by testStartAndStopBrowser test
		assertTrue( Len( selenium.getSessionId() ) );
		// set timeout period to be used when waiting for page to load
		timeout = 30000;
		// rebuild Xindi (reset data in database)
		httpService = new http();
		httpService.setUrl( browserURL & "/index.cfm?rebuild=true" );
		httpService.send();
	}
	
	// run once after each test
	function tearDown() {
		// stop the test
		selenium.stop();
	}	

	// run once after all tests
	function afterTests() {
		// stop Selenium server
		selenium.stopServer();
		// assertion used by testStartAndStopBrowser test
		assertFalse( Len( selenium.getSessionId() ) );
	}	

	function testStartAndStopBrowser() {
		// the asserts for this are in beforeTests and afterTests
	}

	function testHomePageLoads() {
		selenium.open( browserUrl );
		selenium.waitForPageToLoad( timeout );
		assertEquals( "Welcome to Xindi", selenium.getTitle() );
	}

	function testShowPage() {
		selenium.open( browserURL );
		selenium.waitForPageToLoad( timeout );
		selenium.click( "link=Design" );
		selenium.waitForPageToLoad( timeout );
		assertEquals( "Design", selenium.getTitle() );
	}

	function testShowArticle() {
		selenium.open( browserURL );
		selenium.waitForPageToLoad( timeout );
		selenium.click( "link=News" );
		selenium.waitForPageToLoad( timeout );
		selenium.click( "link=exact:Why choose Xindi?" );
		selenium.waitForPageToLoad( timeout );
		assertEquals( "Why choose Xindi?", selenium.getTitle() );
	}
		
	function testContactForm() {
		selenium.open( browserURL & "/index.cfm/enquiry" );
		selenium.waitForPageToLoad( timeout );
		selenium.type( "id=firstname", "test" );
		selenium.type( "id=lastname", "test" );
		selenium.type( "id=email", "test@example.com" );
		selenium.type( "id=message", "test" );
		selenium.click( "id=submit" );
		selenium.waitForPageToLoad( timeout );
		// we expect a fail because no mail server is configured
		assertTrue( selenium.isTextPresent( "Oops!" ) );
	}
	
	function testSearchFeature() {
		selenium.open( browserURL );
		selenium.waitForPageToLoad( timeout );
		selenium.type( "id=searchterm", "welcome" );
		selenium.submit( "id=search" );
		selenium.waitForPageToLoad( timeout );
		assertEquals( "Search Results", selenium.getTitle() );
	}
	
	function testSitemap() {
		selenium.open( browserURL );
		selenium.waitForPageToLoad( timeout );
		selenium.click( "link=Site Map" );
		selenium.waitForPageToLoad( timeout );
		assertEquals( "Site Map", selenium.getTitle() );
	}
	
	function testInvalidLogin() {
		selenium.open( browserURL & "/index.cfm/admin:security" );
		selenium.waitForPageToLoad( timeout );
		selenium.type( "id=username", "foo" );
		selenium.type( "id=password", "bar" );
		selenium.click( "id=login" );
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "Sorry, your login details have not been recognised." ) );
	}
	
	function testValidLogin() {
		doLogin();
		assertTrue( selenium.isTextPresent( "Welcome Default. You have been logged in." ) );
		doLogout();
	}
	
	function testAddEditMoveDeletePage() {
		doLogin();
		// add page
		selenium.open( browserURL & "/index.cfm/admin:pages" );
		selenium.waitForPageToLoad( timeout );
		selenium.click( "css=i.icon-plus-sign" );
		selenium.waitForPageToLoad( timeout );
		selenium.type( "id=title", "test" );
		// use JavaScript to enter content into CKEditor
		selenium.runScript( "CKEDITOR.instances['page-content'].setData('<p>test</p>');" );
		selenium.runScript( "document.getElementById('page-form').onsubmit=function(){CKEDITOR.instances[ 'page-content' ].updateElement();};" );
		selenium.click( "xpath=(//input[@name='submit'])[2]" );
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "regexp:(The page "".*"" has been saved.)" ) );
		// edit page
		selenium.click( "link=test" );
		selenium.waitForPageToLoad( timeout );
		selenium.type( "id=title", "test edit" );		
		selenium.click( "xpath=(//input[@name='submit'])[2]" );
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "regexp:(The page "".*"" has been saved.)" ) );
		// move page
		selenium.click( "//div[@id='content']/table/tbody/tr[10]/td[5]/a/i" );
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "The page ""test edit"" has been moved." ) );
		selenium.click( "//div[@id='content']/table/tbody/tr[9]/td[6]/a/i" );
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "regexp:(The page "".*"" has been moved.)" ) );
		// delete page
		selenium.click( "//div[@id='content']/table/tbody/tr[7]/td[7]/a/i" );
		selenium.waitForPageToLoad( timeout );
		// when we delete a record a confirmation dialog appears
		// the getConfirmation method forces the Ok button to be clicked in the dialog
		selenium.getConfirmation();
		assertTrue( selenium.isTextPresent( "regexp:(The page "".*"" has been deleted.)" ) );
		doLogout();
	}	
	
	function testAddEditDeleteArticle() {
		doLogin();
		// add article
		selenium.open( browserURL & "/index.cfm/admin:news" );
		selenium.waitForPageToLoad( timeout );
		selenium.click( "link=Add article" );
		selenium.waitForPageToLoad( timeout );
		selenium.type( "id=title", "test" );		
		selenium.type( "id=published", "01/07/2012" );	
		// use JavaScript to enter content into CKEditor	
		selenium.runScript( "CKEDITOR.instances['article-content'].setData('<p>test</p>');" );
		selenium.runScript( "document.getElementById('article-form').onsubmit=function(){CKEDITOR.instances[ 'article-content' ].updateElement();};" );
		selenium.click( "id=submit" );
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "regexp:(The article "".*"" has been saved.)" ) );
		// edit article
		selenium.click( "link=test" );
		selenium.waitForPageToLoad( timeout );
		selenium.type( "id=title", "test edit" );		
		selenium.click( "id=submit" );
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "regexp:(The article "".*"" has been saved.)" ) );
		// delete article
		selenium.click( "css=i.icon-remove" );
		// when we delete a record a confirmation dialog appears
		// the getConfirmation method forces the Ok button to be clicked in the dialog
		selenium.getConfirmation();
		selenium.waitForPageToLoad( timeout );		
		assertTrue( selenium.isTextPresent( "regexp:(The article "".*"" has been deleted.)" ) );
		doLogout();
	}
	
	function testViewEnquiry(){
		doLogin();
		selenium.open( browserURL & "/index.cfm/admin:enquiries" );
		selenium.waitForPageToLoad( timeout );
		selenium.click( "css=i.icon-eye-open" );
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "Phasellus ut tortor in erat dignissim eleifend at nec leo!" ) );
		doLogout();
	}
	
	function testDeleteEnquiry(){
		doLogin();
		selenium.open( browserURL & "/index.cfm/admin:enquiries" );
		selenium.waitForPageToLoad( timeout );
		selenium.click( "css=i.icon-remove" );
		// when we delete a record a confirmation dialog appears
		// the getConfirmation method forces the Ok button to be clicked in the dialog
		selenium.getConfirmation();
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "regexp:(The enquiry from "".*"" has been deleted.)" ) );
		doLogout();
	}	
	
	function testAddEditDeleteUser() {
		doLogin();
		// add user
		selenium.open( browserURL & "/index.cfm/admin:users" );
		selenium.waitForPageToLoad( timeout );
		selenium.click( "link=Add user" );
		selenium.waitForPageToLoad( timeout );
		selenium.type( "id=firstname", "test" );		
		selenium.type( "id=lastname", "test" );		
		selenium.type( "id=email", "test@example.com" );		
		selenium.type( "id=username", "test" );		
		selenium.type( "id=password", "test" );		
		selenium.click( "id=submit" );
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "regexp:(The user "".*"" has been saved.)" ) );
		// edit user
		selenium.click( "link=test test" );
		selenium.waitForPageToLoad( timeout );
		selenium.type( "id=firstname", "test edit" );
		selenium.click( "id=submit" );
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "regexp:(The user "".*"" has been saved.)" ) );
		// delete user
		selenium.click( "css=i.icon-remove" );
		// when we delete a record a confirmation dialog appears
		// the getConfirmation method forces the Ok button to be clicked in the dialog
		selenium.getConfirmation();
		selenium.waitForPageToLoad( timeout );
		assertTrue( selenium.isTextPresent( "regexp:(The user "".*"" has been deleted.)" ) );
		doLogout();
	}
	
	function testLogout(){
		doLogin();
		doLogout();
		assertTrue( selenium.isTextPresent( "You have been logged out." ) );		
	}
	
	// login user to content management system
	private function doLogin(){
		selenium.open( browserURL & "/index.cfm/admin:security" );
		selenium.waitForPageToLoad( timeout );
		selenium.type( "id=username", "admin" );
		selenium.type( "id=password", "admin" );
		selenium.click( "id=login" );
		selenium.waitForPageToLoad( timeout );
	}
	
	// logout user from content management system
	private function doLogout(){
		selenium.open( browserURL & "/index.cfm/admin:security/logout" );
		selenium.waitForPageToLoad( timeout );
	}

}