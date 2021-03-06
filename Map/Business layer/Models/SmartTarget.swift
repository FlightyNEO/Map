//
//  SmartTarget.swift
//  Map
//
//  Created by Arkadiy Grigoryanc on 17.12.2019.
//

import CoreLocation

// MARK: - Struct
struct SmartTarget
{

	// MARK: ...Properties
	let dateOfCreated: Date
	let uid: String
	var title: String
	var coordinates: CLLocationCoordinate2D
	var address: String?
	var radius: Double?

	private(set) var numberOfVisits = 0
	private(set) var timeInside: TimeInterval = 0

	var region: CLCircularRegion {
		CLCircularRegion(center: coordinates, radius: radius ?? 100, identifier: uid)
	}

	var entryDate: Date? {
		didSet {
			if entryDate != nil {
				numberOfVisits += 1
				exitDate = nil
			}
		}
	}
	var exitDate: Date? {
		didSet {
			if exitDate != nil {
				timeInside += exitDate?.timeIntervalSince(entryDate ?? Date()) ?? 0
				entryDate = nil
			}
		}
	}

	private enum CodingKeys: String, CodingKey
	{
		case uid
		case title
		case coordinates
		case dateOfCreated
		case address
		case radius
		case numberOfVisits
		case timeInside
		case entryDate
		case exitDate
	}

	// MARK: ...Initialization
	init(uid: String = UUID().uuidString,
		 title: String,
		 coordinates: CLLocationCoordinate2D,
		 address: String? = nil) {

		self.uid = uid
		self.title = title
		self.coordinates = coordinates
		self.dateOfCreated = Date()
		self.address = address
	}

	// MARK: ...Internal methods
	mutating func setInitialAttendance() {
		entryDate = nil
		exitDate = nil
		numberOfVisits = 0
		timeInside = 0
	}
}

// MARK: - Codable
extension SmartTarget: Codable
{
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		uid = try container.decode(String.self, forKey: .uid)
		title = try container.decode(String.self, forKey: .title)
		coordinates = try container.decode(CLLocationCoordinate2D.self, forKey: .coordinates)
		dateOfCreated = try container.decode(Date.self, forKey: .dateOfCreated)
		address = try? container.decode(String.self, forKey: .address)
		radius = try? container.decode(Double.self, forKey: .radius)
		numberOfVisits = try container.decode(Int.self, forKey: .numberOfVisits)
		timeInside = try container.decode(TimeInterval.self, forKey: .timeInside)
		entryDate = try? container.decode(Date.self, forKey: .entryDate)
		exitDate = try? container.decode(Date.self, forKey: .exitDate)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(uid, forKey: .uid)
		try container.encode(title, forKey: .title)
		try container.encode(coordinates, forKey: .coordinates)
		try container.encode(dateOfCreated, forKey: .dateOfCreated)
		try container.encode(address, forKey: .address)
		try container.encode(radius, forKey: .radius)
		try container.encode(numberOfVisits, forKey: .numberOfVisits)
		try container.encode(timeInside, forKey: .timeInside)
		try container.encode(entryDate, forKey: .entryDate)
		try container.encode(exitDate, forKey: .exitDate)
	}
}

// MARK: - Comparable
extension SmartTarget: Comparable
{
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.uid == rhs.uid
	}

	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.dateOfCreated < rhs.dateOfCreated
	}
}

extension SmartTarget: Identity
{
	static func === (lhs: Self, rhs: Self) -> Bool {
		lhs.uid == rhs.uid &&
		lhs.address == rhs.address &&
		lhs.radius == rhs.radius &&
		lhs.title == rhs.title &&
		lhs.coordinates == rhs.coordinates
	}

	static func !== (lhs: Self, rhs: Self) -> Bool {
		lhs.uid != rhs.uid ||
		lhs.address != rhs.address ||
		lhs.radius != rhs.radius ||
		lhs.title != rhs.title ||
		lhs.coordinates != rhs.coordinates
	}
}

// MARK: - Hashable
extension SmartTarget: Hashable
{
	func hash(into hasher: inout Hasher) {
		hasher.combine(uid)
	}
}

// MARK: - Custom string convertible
extension SmartTarget: CustomStringConvertible
{
	var description: String { "uid: " + uid + ", title: " + title }
}

extension SmartTarget
{
	var annotation: SmartTargetAnnotation {
		SmartTargetAnnotation(uid: uid, title: title, coordinate: coordinates)
	}
}
