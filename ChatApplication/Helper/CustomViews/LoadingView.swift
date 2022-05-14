//
//  LoadingView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct LoadingView: View {

    @State
    public  var isAnimating          : Bool    = true
    public  var width                : CGFloat = 4
    public  var color                : Color   = Color.orange
    
    public init(isAnimating:Bool = false, width: CGFloat = 4, color: Color = Color.orange) {
        self.isAnimating = isAnimating
        self.width       = width
        self.color       = color
    }
    
    var body: some View {
        
        GeometryReader{ reader in
            Circle()
                .trim(from: 0, to: $isAnimating.wrappedValue ? 1 : 0.1)
                .stroke(style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 10))
                .fill(AngularGradient(colors: [color, .random,.random , .teal], center: .top))
                .frame(width: reader.size.width, height: reader.size.height)
                .rotationEffect(Angle(degrees: $isAnimating.wrappedValue ? 360 : 0))
                .onAppear {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 2).delay(0.05).repeatForever(autoreverses: true)) {
                            self.isAnimating.toggle()
                        }
                    }
                }
        }
    }
}


struct LoadingView_Previews: PreviewProvider {
    
    @State static var isAnimating = true
    
    static var previews: some View {
        if isAnimating{
            LoadingView(width: 3)
                .frame(width: 36, height: 36)
        }else{
            Color.orange
                .ignoresSafeArea()
        }
    }
}
