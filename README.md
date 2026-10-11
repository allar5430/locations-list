# LocationsList App 📍🌍
    This application shows locations list which come from custom endpoint. If name not come for specific city, application uses apple reverse geocoding to receive it based on coordinates.
    App has ability to add custom location with 2 different scenarios: 
1. based on city name - call apple geocoding api to receive coordinates 
2. based on current user location - resolve coordinates with CLLocationManager.

Once user tap on location - wikipedia app opens on Places tab and show corresponding location.

# Wikipedia app
Use this [Fork](https://github.com/allar5430/wikipedia-ios) with deeplink-navigation branch

## Application stack
- Swift 6
- SwiftUI
- Swift Concurrency
- MVVM + Router
- XCTest
- Accessibility
    - Dynamic Text Size
    - VoiceOver
- CoreLocation for geocoding
- os for logging

## Example of work
https://github.com/user-attachments/assets/1b5968f0-5c04-44a3-ad1e-1a7c56a3cba6

## Get Locations List UX
```mermaid
sequenceDiagram
    actor User
    participant Screen as Locations list screen
    participant Locations as Locations request
    participant Names as Location name resolution
    participant Wikipedia as Wikipedia app

    User->>Screen: Opens locations screen
    Screen-->>User: Shows loading indicator
    Screen->>Locations: Request locations

    alt Request succeeds
        Locations-->>Screen: Return locations
        Screen-->>User: Shows locations list

        loop For each location
            alt Location already has a name
                Screen-->>User: Shows location name and coordinates
            else Location name is missing
                Screen-->>User: Shows skeleton row
                Screen->>Names: Resolve name from coordinates

                alt Name resolution succeeds
                    Names-->>Screen: Return location name
                    Screen-->>User: Replaces skeleton with location name
                else Name resolution fails
                    Names-->>Screen: Name unavailable
                    Screen-->>User: Shows default "Unknown" name
                end
            end
        end

        User->>Screen: Taps a named location row
        Screen->>Wikipedia: Opens wikipedia://places?lat=...&long=...

        alt Wikipedia URL cannot be created or opened
            Wikipedia-->>Screen: Opening fails
            Screen-->>User: Remains on locations list
        else Wikipedia opens successfully
            Wikipedia-->>User: Shows selected location
        end
    else Request fails
        Locations-->>Screen: Request failure
        Screen-->>User: Shows locations unavailable screen
    end
```

User-facing states:

- While the locations request is running, the screen shows a loading indicator.
- If the request succeeds, the locations list appears.
- Locations with known names show their name immediately.
- Locations without names show a skeleton row while name resolution is running.
- A successful name resolution replaces the skeleton with the resolved name.
- A failed name resolution replaces the skeleton with the default `Unknown` name.
- A failed initial locations request shows the locations unavailable screen.

## Add Custom Location UX
```mermaid
sequenceDiagram
    actor User
    participant List as Locations list screen
    participant Sheet as Add custom location sheet
    participant Add as Add location operation
    participant Geocoding as Location name lookup
    participant Current as Current location service

    User->>List: Taps "+"
    List-->>User: Presents Add custom location sheet
    Sheet-->>User: Focuses the Location field

    alt User cancels
        User->>Sheet: Taps "Cancel"
        Sheet-->>User: Dismisses sheet
        User-->>List: Returns to locations list

    else User adds a location by name
        User->>Sheet: Enters a location name
        Sheet-->>User: Enables "Done"
        User->>Sheet: Taps "Done"
        Sheet-->>User: Replaces "Done" with loading indicator
        Sheet->>Add: Add custom location by name
        Add->>Geocoding: Find coordinates for entered name

        alt Location cannot be found
            Geocoding-->>Add: Lookup fails
            Add-->>Sheet: Add operation fails
            Sheet-->>User: Shows "Unable to find location"
            Sheet-->>User: Keeps sheet open for editing or cancellation
        else Location is found
            Geocoding-->>Add: Return coordinates
            Add-->>Sheet: Add operation succeeds
            Sheet-->>List: Adds location to the shared list
            Sheet-->>User: Dismisses sheet
            List-->>User: Shows updated locations list
        end

    else User adds the current location
        User->>Sheet: Enables "Use Current Location"
        User->>Sheet: Enters a display name
        User->>Sheet: Taps "Done"
        Sheet-->>User: Replaces "Done" with loading indicator
        Sheet->>Add: Add current location with display name
        Add->>Current: Request current coordinates

        alt Permission denied or location unavailable
            Current-->>Add: Location request fails
            Add-->>Sheet: Add operation fails
            Sheet-->>User: Shows "Unable to find location"
            Sheet-->>User: Keeps sheet open for editing or cancellation
        else Current coordinates are received
            Current-->>Add: Return coordinates
            Add-->>Sheet: Add operation succeeds
            Sheet-->>List: Adds location to the shared list
            Sheet-->>User: Dismisses sheet
            List-->>User: Shows updated locations list
        end
    end

    opt User adds another custom location
        User->>List: Taps "+" again
        List-->>User: Presents a fresh Add custom location sheet
    end
```

## Dark mode
<img width="250" src="https://github.com/user-attachments/assets/e7c7bbec-f03d-4b5a-918d-72ce9d04e75c" />
<img width="250" src="https://github.com/user-attachments/assets/8140b64d-556f-4418-8f0c-c9c2e4589d25" />

## Large text
<img width="250" src="https://github.com/user-attachments/assets/647c5147-bc2f-4194-bd9c-1c65e4ff75bb" />
