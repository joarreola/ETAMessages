# ETAMessages
Class project

- How to test (recommend to do in extended View: ^)

	Mobile Mode:

		- Tap Enable button:
		  Display changes from "- locationManager..." to local coordinates.

		- Update location via simulator menu:
		  Debug -> Location -> CustomLocation:
		  Blue dot will move to new location, mapView will be centered.

		- Tap Disable button:
		  Display is cleared. Local coordinates removed.


	Stationary Mode:

		- Tap Poll button: (this is for test purposes only, will removed)
		  local and remote coordinates are displayed. Remote user is noted
		  with a pointAnnotation (red pin), local user noted with blue dot.

		- Tap Poll button again:
		  eta and distance data is appended to the display. mapView is
		  refreshed, center between users, span'ed appropriately to cover
		  most of mapView.

		- Move local user closer to remote user (backwards but works to
		  test eta notification trigger code) via Simulator:
		  Debug -> Location -> CustomLocation. Changing the 3rd and 4th
		  decimals to match remote coordinates is sufficient to trigger the
		  ETA==0 condition (<50 sec):
		  Local user blue dot moves to red pin. Polling stops. Display
		  notes "Oscar has arrived"

		- Tap Disable button:
		  MapView is refresh showing just the blue dot, and re-spanned.
		
	Known Issues:
		- Can't restart polling after Disable or Has-Arrived notification.
		- Reloading the app via the txt-msgs app-store produces strange
		  images on the simulator.
		
		
- How did you organize the project's code and resources?

  - Cloud.swift
    Upload, fetch, save, delete a record to/from iCloud repo.
    
    - Update semaphore.wait() from distantFuture to 5 sec.
    - Switch to Public database.
    
  - Uploading.swift - New
  	Manage mobile mode behavior, with localUser and single packet
  
  
  - Users.switf - New
  	Knows user name and location info
  	
  	- replace set/getname() with set/getName().
  	  
  - Poll.swift
    Poll iCloud repo for content changes in remote-User's location record.
    
    - Instantiate MapUpdate vs. passing. Call mapUpdate.displaUpdate() for
      display/console updates.
    - Remove etaPointer parameter from pollRemote() and as arg to
      eta.getEtaDistance() call.
    - Create my Distance property. Populate eta from eta.getEta() v.s
      from pointer. Call eta.getEtaDistance() in background v.s man thread.
      Make UI updating calls in main thread.
    - Convert pollRemote() to GrandCentralStation per class slides.
    - Update semaphore.wait() from distantFuture to 5 sec.
    - Update to user Users and Uploading classes
    - Replace remoteUser with remoteUserName. No need to pass self.etaOriginal
      nor self.myEta to etaNotification().
    - Remove fetchRemote() code duplication, instead use Cloud instance and
      call fetchRecord().
    - set self.rmoteFound based on rlat ==/!= nil
    
    
  - MapUpdate.swift
    Manage mapView updates (addPin) and getting ETA and distance between
    local and remote devices/users.
    
    - Moved getEtaDistance() to Eta.swift.
    - Fixed centerView for when remote location is under local location.
    - Remove unused var declarations. Update centerView() logic. create
      refreshMapView() method. Create displayUpdate() method.
    - Fix multiple pointAnnotations bug after previous commit.
    -  Replace delta param with eta instance. Add delta-computing switch.
    - Update to user Users and Uploading classes
    - Fix refreshMapView() parameter list for single-packet case.
  
  
  - Location.switch
    Location coordinate structure.
    
    - remove remote location properties.
    
    
  - Eta.swift
    eta value and etaPointer structure.
    moved in getEtaDistance() from MapUpdate.swift
    
    - Remove display parameter. Instantiate MapUpdate. Call mapUpdate.
      displayUpdate().
    - Add set/getDistance(). Remove eta and etaPointer from params list.
      Use setEta(), setDistance(), self.loadPointer() in getEtaDistance().
    - Initialize eta and distance to nil.
    - Add user location instance


  - GPSsLocation.swift
  	Manages local and remote location updates when CLLocation Framework
  	calls locationManager()
  	
  	- Added.
 
  - MessagesViewController.swift
    Manages the UI implemented in IBACtion functions enable() and poll().
    The mobile user enters the app via the Enable button, the stationary
    users does so via the Poll button. Local location changes come in to
    the locationManager() CLLOcation callback function.
    
    A UILabel notes local and remote coordinate data, and eta/distance
    info. At times it reports specific app state, sort of like a console.
    
    - Call mapUpdate.refreshMapView(). Call mapUpdate.displayUpdate().
    - Remove etaPointer parameter. Use eta.loadPointer(). Remove etaPointer
      to eta.getEtaDistance() calls.
    - Update all mapUpdate.refreshMapView() calls to pass eta instance
      vs. delta value.
    - Update to user Users and Uploading classes
    - Update to use GPSLocation class. Remove check_remote()
    - Rename "poll" to "pollManager"
    - Don't upload local coordinates in Poll mode.
 
- What is the project supposed to do?
  In an environment consiting of two mobile devices, the ETAMessages app
  delivers local notification of remote-user's ETA to Stationary device,
  and uploads location data to iCloud from the Mobile-user's device.
  
- What is working?
  All of the above are working as expected. Remote-User location can be
  read from iCloud records, as the devices get closer, the mapView span is
  updated to zoom in. Mobile device location coordinates are updated to
  iCloud repo. ETA and distance data extraction is working. The polling
  for remore-location code is in, but needs some refinements. A while loop
  is launched in a separate thread, will switch to GCS.
  The etaNotifications() method exits but needs refinement. Need to create
  an appropriate function to translate distance to mapView span.
  
- What is not?
  Getting random app crashes, likely assocciated with the use of an
  UnsafeMutableRawPointer (for eta data storage in completionhandled
  closures). Getting better, but not yet cleared.
   
  The latest commit looks much better. No crashes yet on devs or
  simulator. Converted Eta from struct to class, and fully inited
  pointer in Eta's init().
  
  The random crashes are gone.
  
- What should a reviewer do in order to test your project?
  Location coordinates can be updated in the simulator via Debug->Location.
  Depending on the app mode (mobile/stationary) Debug->Location will move
  the blue dot or the red pin. We'll see if I can have the app behave
  correctly if the blue dot moves toward the red pin in poll mode.
  
  Actually, the red pin can only be moved by updating the location record
  manually in the iCloud repo. Was able to do that last week, but can't
  after Apple's update to the developers/CloudKit Dashboard. Also, can't
  run the app on a device due to new code signing requirements. This
  appears to be a recent Apple regression.
  
- Are there any problems that you know you need to fix?
  Yes, the random crashes mentioned above.
  
  The latest commit looks much better. No crashes yet on devs or
  simulator. Converted Eta from struct to class, and fully inited
  pointer in Eta's init().
  
  The random crashes are gone.
  
- Are there any areas where you would like help?
  Not yet. Got good input/suggestions from Michael in 1st code submittion, will work on them.
  
  
- TODO:

	- Move map refreshing code out of getEtaDistance() closure. Focus just
	  on eta and distance data. -- DONE
	- Convert poll-loop to GrandCentralStation per class slides. -- DONE
	- update all semaphores to 5 seconds -- DONE
	- sleep -> NStimer: wait for next class
	- Implement thread synchronization with conditional-vars/mutexes.
	- Implement local notifications.
	- Consider pop-up menu to enable/disable stationary and mobile modes.
	  Or possibly just note if enabled/disabled
	  by changing the button item background? :-)
	  Then Remove the Disable button.
	- Add directions overlay to mapView.
	- Instantiate pe-user Location instances -- DONE
  	- Implement Class Diagram classes:
  		- EtaNotifications
  		- Uploading -- DONE
  		- GPSsLocation -- DONE
  		- Users -- DONE
  	- Have app run properly when both Uploading and Polling modes are
  	  enabled. Need this to test polling without manually updating
  	  the record in CloudKit Dashboard. -- DONE
  
