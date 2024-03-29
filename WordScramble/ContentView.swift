//
//  ContentView.swift
//  WordScramble
//
//  Created by Mario Alberto Barragán Espinosa on 26/10/19.
//  Copyright © 2019 Mario Alberto Barragán Espinosa. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @State private var score = 0
        
    func renderOffset(_ geoRect: CGRect, _ fullRect: CGRect) -> CGFloat {
        let height = fullRect.maxY * 0.6
        if geoRect.minY < height {
            return 0
        }
        return geoRect.minY - height
    }
    
    func renderColor(_ geoRect: CGRect, _ fullRect: CGRect) -> Color {
        let startPosition = fullRect.minY
        let endPosition = fullRect.maxY
        let itemPosition = geoRect.minY
        
        let hue = (itemPosition - startPosition) / (endPosition - startPosition)
        
        let color = Color(hue: Double(hue), saturation: 0.7, brightness: 0.8)
        return color
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    TextField("Enter your word", text: self.$newWord, onCommit: self.addNewWord)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .autocapitalization(.none)

                    List(self.usedWords, id: \.self) { word in
                        GeometryReader { geo in
                            HStack {
                                Image(systemName: "\(word.count).circle")
                                    .foregroundColor(self.renderColor(geo.frame(in: .global), geometry.frame(in: .global)))
                                Text(word)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibility(label: Text("\(word), \(word.count) letters"))
                            .frame(width: geo.size.width, alignment: .leading)
                            .offset(x: self.renderOffset(geo.frame(in: .global), geometry.frame(in: .global)), y: 0.0)
                            .onTapGesture {
                                print("Global geo center: maxY \(geo.frame(in: .global).maxY) minY \(geo.frame(in: .global).minY) midY: \(geo.frame(in: .global).midY)")
                                print("Global geometry center: maxY \(geometry.frame(in: .global).maxY) minY \(geometry.frame(in: .global).minY) midY: \(geometry.frame(in: .global).midY)")
                            }
                        }
                    }
                    Text("Current score: \(self.score)")
                }
                .navigationBarTitle(self.rootWord)
                .onAppear(perform: self.startGame)
                .alert(isPresented: self.$showingError) {
                    Alert(title: Text(self.errorTitle), message: Text(self.errorMessage), dismissButton: .default(Text("OK")))
                }
                .navigationBarItems(leading: Button(action: {
                    self.startGame()
                }) {
                    Text("start game")
                })
            }
        }
    }
    
    func addNewWord() {
        // lowercase and trim the word, to make sure we don't add duplicate words with case differences
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // exit if the remaining string is empty
        guard answer.count > 0 else {
            return
        }

        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original")
            return
        }

        guard isPossible(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }

        guard isReal(word: answer) else {
            wordError(title: "Word not possible", message: "That isn't a real word.")
            return
        }
        usedWords.insert(answer, at: 0)
        score += answer.count
        newWord = ""
    }
    
    func startGame() {
        // 1. Find the URL for start.txt in our app bundle
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            // 2. Load start.txt into a string
            if let startWords = try? String(contentsOf: startWordsURL) {
                // 3. Split the string up into an array of strings, splitting on line breaks
                let allWords = startWords.components(separatedBy: "\n")

                // 4. Pick one random word, or use "silkworm" as a sensible default
                rootWord = allWords.randomElement() ?? "silkworm"
                
                // 5. Restart used words array and score
                usedWords = [String]()
                score = 0
                // If we are here everything has worked, so we can exit
                return
            }
        }

        // If were are *here* then there was a problem – trigger a crash and report the error
        fatalError("Could not load start.txt from bundle.")
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word) && !(word == rootWord)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord

        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }

        return true
    }
    
    func isReal(word: String) -> Bool {
        if word.count < 3 {
            return false
        }
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")

        return misspelledRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
