import SwiftUI

struct AgePage: View {
    @Binding var age: Int
    private let ages = Array(13...100)
    
    var body: some View {
        FlowPageContainer(title: "How old are you?") {
            VStack(alignment: .center, spacing: 16) {
                
                Text("Select your age using the wheel below.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Picker("Select your age", selection: $age) {
                    ForEach(ages, id: \.self) { age in
                        Text("\(age)")
                            .font(.title2.weight(.medium))
                            .tag(age)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)
                .clipped()
                .padding(.horizontal)
                
                if age > 0 {
                    Text("Selected Age: \(age)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .onAppear {
                if age == 0 { age = 18 } // default
            }
        }
    }
}
/*#Preview{
    AgePage(age: .constant(21))
        
}
*/
