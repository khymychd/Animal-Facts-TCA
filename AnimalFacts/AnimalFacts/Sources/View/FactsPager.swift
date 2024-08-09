//

import SwiftUI

struct FactsPager: View {
    
    var dataSource: [Int] = (0..<10).map({ $0 })
    
    @State
    var selectedIndex: Int = 0
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    var body: some View {
        TabView(selection: $selectedIndex, content:  {
            ForEach(dataSource, id: \.self) { index in
                VStack {
                    Image(uiImage: .placeholder)
                        .resizable()
                        .aspectRatio(315 / 234,contentMode: .fit)
                        .padding(.all, 10)
                    
                    Text("Some Fact\ns\ns\ns\ns")
                        .multilineTextAlignment(.center)
                        .frame(minHeight: 100)
                        .padding(.top, 7)
                    
                    HStack() {
                        directionButton(.back) {
                            
                        }
                        Spacer()
                        directionButton(.forward) {
                            
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 22)
                }
                .background(content: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.3) ,radius: 30, y: 30)
                })
                .padding(.horizontal, horizontalSizeClass == .compact ? 20 : 120)
                .onAppear(perform: {
                    print("ITEM Number index \(index)")
                })
            }
        })
        .navigationTitle("Title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: navigationBarButton("arrow.left") {
                
            },
            trailing: navigationBarButton("square.and.arrow.up") {
                
            }
        )
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color.background)
        .toolbarBackground(Color.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    @ViewBuilder
    private func directionButton(_ image: UIImage, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 52, height: 52)
        }
    }
    
    @ViewBuilder
    private func navigationBarButton(_ name: String, _ action: @escaping () -> Void) -> some View {
        Image(systemName: name)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .tint(.black)
            .onTapGesture {
                action()
            }
    }
}

#Preview {
    NavigationStack {
        FactsPager()
    }
}
