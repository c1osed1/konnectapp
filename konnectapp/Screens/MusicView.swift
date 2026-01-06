import SwiftUI

struct MusicView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Музыка")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                ForEach(0..<10) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appAccent.opacity(0.3))
                            .frame(width: 60, height: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Название трека")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Исполнитель")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.83))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 100)
        }
    }
}

