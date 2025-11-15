import SwiftUI
import CoreLocation

struct LocationAccessPage: View {
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        //  Read the observed value into a local constant INSIDE body
        let status = locationManager.authorizationStatus
        
        FlowPageContainer(title: "Enable Location Access") {
            VStack(spacing: 16) {

                Image(systemName: "location.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(AppTheme.accent)
                    .symbolEffect(.bounce, value: locationManager.coordinates)

                Text("Enable Location Access")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("We use your location to show nearby creators and collaborations. Your exact location is never shared publicly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                
                Button {
                    locationManager.requestLocationAccess()
                } label: {
                    Text(buttonTitle(for: status))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(status == .authorizedWhenInUse)
                .padding(.horizontal)

                if status == .denied {
                    Text("You can enable location in Settings → Privacy → Location Services.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
        }
    }

    //  helper function that takes a value, not a wrapper
    private func buttonTitle(for status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return "Location Enabled "
        case .denied:
            return "Open Settings"
        default:
            return "Allow Location Access"
        }
    }
}
