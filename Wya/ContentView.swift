//
//  ContentView.swift
//  Wya
//
//  Created by Petter Staveland on 12/06/2025.
//
import SwiftUI
import MapKit
import CoreLocation
import MultipeerConnectivity

// MARK: - Models
struct Person: Identifiable, Codable {
    let id = UUID()
    var name: String
    var emoji: String
    var relationship: String
    var location: CLLocationCoordinate2D
    var lastUpdated: Date
    var isActive: Bool
    var color: RGBColor
    
    init(name: String, emoji: String, relationship: String, location: CLLocationCoordinate2D, isActive: Bool = true, color: RGBColor) {
        self.name = name
        self.emoji = emoji
        self.relationship = relationship
        self.location = location
        self.lastUpdated = Date()
        self.isActive = isActive
        self.color = color
    }
}

struct RGBColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

struct LocationAlert: Identifiable, Codable {
    let id = UUID()
    var name: String
    var location: CLLocationCoordinate2D
    var radius: Double
    var members: [UUID]
    var alertType: AlertType
    
    enum AlertType: String, Codable, CaseIterable {
        case arrival = "Arrival"
        case departure = "Departure"
        case both = "Both"
    }
}

// MARK: - Extensions
extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
}

// MARK: - View Model
class WyaViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var people: [Person] = []
    @Published var selectedPerson: Person?
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var showingAddPerson = false
    @Published var locationAlerts: [LocationAlert] = []

    let locationManager = CLLocationManager()
    let multipeerSession = MultipeerSession()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        multipeerSession.receivedLocation = { [weak self] peer, coordinate in
            self?.updatePerson(named: peer.displayName, with: coordinate)
        }
    }

    private func updatePerson(named name: String, with coordinate: CLLocationCoordinate2D) {
        if let index = people.firstIndex(where: { $0.name == name }) {
            people[index].location = coordinate
            people[index].lastUpdated = Date()
        } else {
            let color = randomColor()
            let newPerson = Person(name: name, emoji: "👤", relationship: "Friend", location: coordinate, color: color)
            people.append(newPerson)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coord = location.coordinate
        if let index = people.firstIndex(where: { $0.relationship == "Me" }) {
            people[index].location = coord
            people[index].lastUpdated = Date()
        } else {
            let me = Person(name: "Me", emoji: "🧍", relationship: "Me", location: coord, color: RGBColor(red: 0.2, green: 0.7, blue: 0.4))
            people.append(me)
        }
        mapRegion.center = coord
        multipeerSession.send(location: coord)
    }

    private func randomColor() -> RGBColor {
        RGBColor(red: Double.random(in: 0.2...1.0),
                 green: Double.random(in: 0.2...1.0),
                 blue: Double.random(in: 0.2...1.0))
    }
    
    func addPerson(_ person: Person) {
        people.append(person)
    }
    
    func deletePerson(_ person: Person) {
        people.removeAll { $0.id == person.id }
    }
    
    func centerOnPerson(_ person: Person) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            mapRegion.center = person.location
            mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            selectedPerson = person
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var viewModel = WyaViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(0)
            
            PeopleListView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("People", systemImage: "person.3.fill")
                }
                .tag(1)
            
            AlertsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Alerts", systemImage: "bell.fill")
                }
                .tag(2)
            
            SettingsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

// MARK: - Map View
struct MapView: View {
    @EnvironmentObject var viewModel: WyaViewModel
    @State private var showingPersonDetail = false
    @State private var trackingMode: MapUserTrackingMode = .follow
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $viewModel.mapRegion,
                showsUserLocation: true,
                userTrackingMode: $trackingMode,
                annotationItems: viewModel.people) { person in
                MapAnnotation(coordinate: person.location) {
                    PersonAnnotation(person: person) {
                        viewModel.selectedPerson = person
                        showingPersonDetail = true
                    }
                }
            }
            .ignoresSafeArea(.all, edges: .top)
            
            VStack {
                HStack {
                    // Status Bar Background
                    Color.clear
                        .frame(height: 50)
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea()
                }
                
                PeopleCarousel()
                    .environmentObject(viewModel)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            trackingMode = .follow
                        }) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            withAnimation {
                                viewModel.mapRegion.span = MKCoordinateSpan(
                                    latitudeDelta: max(0.001, viewModel.mapRegion.span.latitudeDelta * 0.7),
                                    longitudeDelta: max(0.001, viewModel.mapRegion.span.longitudeDelta * 0.7)
                                )
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            withAnimation {
                                viewModel.mapRegion.span = MKCoordinateSpan(
                                    latitudeDelta: min(10, viewModel.mapRegion.span.latitudeDelta * 1.3),
                                    longitudeDelta: min(10, viewModel.mapRegion.span.longitudeDelta * 1.3)
                                )
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingPersonDetail) {
            if let person = viewModel.selectedPerson {
                PersonDetailView(person: person)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Person Annotation
struct PersonAnnotation: View {
    let person: Person
    let action: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(person.color.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                    
                    Circle()
                        .fill(person.color.color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(person.emoji)
                                .font(.title2)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                Text(person.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.7)))
                    .offset(y: -5)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - People Carousel
struct PeopleCarousel: View {
    @EnvironmentObject var viewModel: WyaViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.people) { person in
                    PersonCard(person: person)
                        .onTapGesture {
                            viewModel.centerOnPerson(person)
                        }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Person Card
struct PersonCard: View {
    let person: Person
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(person.color.color)
                    .frame(width: 50, height: 50)
                
                Text(person.emoji)
                    .font(.title2)
            }
            
            Text(person.name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(timeAgoString(from: person.lastUpdated))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity) { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        } perform: {}
    }
    
    func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

// MARK: - People List View
struct PeopleListView: View {
    @EnvironmentObject var viewModel: WyaViewModel
    @State private var showingAddPerson = false
    @State private var showingInvite = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.people) { person in
                    PersonRow(person: person)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deletePerson(viewModel.people[index])
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Your People")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingInvite = true }) {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPerson = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPerson) {
            AddPersonView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingInvite) {
            InviteView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Person Row
struct PersonRow: View {
    let person: Person
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(person.color.color)
                    .frame(width: 60, height: 60)
                
                Text(person.emoji)
                    .font(.largeTitle)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.headline)
                
                Text(person.relationship)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Updated \(timeAgoString(from: person.lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack {
                Image(systemName: person.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                    .foregroundColor(person.isActive ? .green : .orange)
                    .font(.title2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60)) minutes ago"
        } else {
            return "\(Int(interval / 3600)) hours ago"
        }
    }
}

// MARK: - Add Person View
struct AddPersonView: View {
    @EnvironmentObject var viewModel: WyaViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var relationship = ""
    @State private var selectedEmoji = "👤"
    @State private var selectedColor = Color.blue
    
    let emojis = ["👨", "👩", "👦", "👧", "👴", "👵", "👶", "🧒", "👱‍♂️", "👱‍♀️"]
    let relationships = ["Friend", "Family", "Partner", "Roommate", "Colleague", "Classmate", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    
                    Picker("Relationship", selection: $relationship) {
                        ForEach(relationships, id: \.self) { rel in
                            Text(rel).tag(rel)
                        }
                    }
                }
                
                Section("Avatar") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.largeTitle)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(selectedEmoji == emoji ? Color.blue.opacity(0.3) : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(selectedEmoji == emoji ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedEmoji = emoji
                                }
                        }
                    }
                }
                
                Section("Color") {
                    ColorPicker("Person Color", selection: $selectedColor)
                }
            }
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let color = UIColor(selectedColor)
                        var red: CGFloat = 0
                        var green: CGFloat = 0
                        var blue: CGFloat = 0
                        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
                        
                        let newPerson = Person(
                            name: name,
                            emoji: selectedEmoji,
                            relationship: relationship,
                            location: CLLocationCoordinate2D(
                                latitude: viewModel.mapRegion.center.latitude + Double.random(in: -0.01...0.01),
                                longitude: viewModel.mapRegion.center.longitude + Double.random(in: -0.01...0.01)
                            ),
                            color: RGBColor(red: Double(red), green: Double(green), blue: Double(blue))
                        )
                        viewModel.addPerson(newPerson)
                        dismiss()
                    }
                    .disabled(name.isEmpty || relationship.isEmpty)
                }
            }
        }
    }
}







// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
