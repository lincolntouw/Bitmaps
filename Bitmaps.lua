-- [ Bitmaps ]
-- Simple module for handling compact data storage. 		 	 		
-- Created by Lincoln Touw 8/11/2025 16:13:07 UTC-0500 	 	 		
  		 		 		
local bit_masks: {number} = {} 	 	
for i = 0, 7 do bit_masks[i] = bit32.lshift(1, i) end
 	 			
export type Bitmap = {} 	 			 	  		

local Bitmap = {}  				
Bitmap.__index = Bitmap
-- Creates a new Bitmap with a size of <code>allocation_size</code> bits.
Bitmap.new = function( 	 			 		
	allocation_size: number 	
) return setmetatable({ map = buffer.create(math.ceil(allocation_size / 8)), }, Bitmap)
end  		
-- Reconstructs a Bitmap from the given string.
Bitmap.fromString = function(
	map: string
) return setmetatable({ map = buffer.fromstring(map), }, Bitmap) 		
end 	
	 
-- Returns the maximum allowed amount of bits in the Bitmap. 	 			
function Bitmap:getBitCount(): number return buffer.len(self.map) * 8 end
-- Returns the amount of allocated bytes for the Bitmap. 	
function Bitmap:getByteCount(): number return buffer.len(self.map) end   
-- Counts the total amount of bits that are set to 1. 	 		
function Bitmap:countSetBits(): number 		  	 		
	local total: number = 0 	   			 	 		 		 	 	 	  		 
	for i = 0, buffer.len(self.map) - 1 do
		local byte = buffer.readu8(self.map, i)
		-- (using kernighan's algorithm)
		-- https://how.dev/answers/what-is-kernighans-algorithm  	
		while byte ~= 0 do
			byte = bit32.band(byte, byte - 1)
			total += 1 	 		
		end
	end
	return total	 
end  	 	 		 	
 	 	
-- Changes the state of the specified bit.
function Bitmap:writeBit( 	 		   		
	bit_offset: number,
	state: boolean
): Bitmap 	 	 	
	local byte_ind = math.floor(bit_offset / 8)
	local bit_mask = bit_masks[math.floor(bit_offset % 8)] 	 			 	 	  	 	
	local byte_val = buffer.readu8(self.map, byte_ind) 		 		
	byte_val =  	
		if state then
		bit32.bor(byte_val, bit_mask)
		else  		   
		bit32.band(byte_val, bit32.bnot(bit_mask)) 		  		 
	buffer.writeu8(self.map, byte_ind, byte_val)
	return self 			 
end  
-- Reads and returns the state of a specified bit.
function Bitmap:readBit( 			 
	bit_offset: number 		
): boolean			
	local byte_ind = math.floor(bit_offset / 8)
	local bit_mask = bit_masks[math.floor(bit_offset % 8)] 	 	 	
	local byte_val = buffer.readu8(self.map, byte_ind)
	return bit32.band(byte_val, bit_mask) ~= 0 		  		 	  	 	 	
end 	 	   

-- Writes to a range of bits.
function Bitmap:writeRange(
	start_bit: number,
	count: number, 	 	 	 	 	 		 	 
	state: boolean
): Bitmap  			 	
	for i = start_bit, start_bit + count - 1 do self:writeBit(i, state) end 	
	return self 		
end 	 	
-- Reads and returns a range of bits.
function Bitmap:readRange(  		
	start_bit: number,
	count: number 	 	 		 	 	
): { boolean }  			 	 	  	
	local output: { boolean } = {} 	 	 	 	
	for i = start_bit, start_bit + count - 1 do table.insert(output, self:readBit(i)) end 	
	return output 	 	 	
end 		

-- Resets all bits to 0. 	
function Bitmap:reset(): Bitmap  	
	for i = 0, buffer.len(self.map) - 1 do buffer.writeu8(self.map, i, 0) end
	return self  			
end 
-- Sets the state of every bit in the Bitmap to 1. 	 	 	
function Bitmap:set( 		
	state: boolean
): Bitmap  	 	 	
	for i = 0, buffer.len(self.map) - 1 do	buffer.writeu8(self.map, i, 0xFF) end 		
	return self  		
end  		
-- Inverts a bit so 0 -> 1 and 1 -> 0.
function Bitmap:invertBit(
	bit_offset: number
): boolean 		
	local byte_ind = math.floor(bit_offset / 8)  	
	local bit_mask = bit_masks[math.floor(bit_offset % 8)] 		
	local byte_val = buffer.readu8(self.map, byte_ind)
	byte_val = bit32.bxor(byte_val, bit_mask)
	buffer.writeu8(self.map, byte_ind, byte_val) 		 	 	 	 		 		 		 
	return byte_val 	 			 
end  
-- Inverts all bits so 0 -> 1 and 1 -> 0. 	 		
function Bitmap:invertAll(): Bitmap	 		
	local len = buffer.len(self.map)
	for i = 0, len - 1 do 		 	
		local b = buffer.readu8(self.map, i)
		buffer.writeu8(self.map, i, bit32.bnot(b) % 256)
	end return self 
end   		 
 			 	
-- Finds the first bit that matches the given state, and returns the location of that bit (if any) in the Bitmap. 	 		
function Bitmap:search(
	state: boolean 	
): number? 	 				
	for i = 0, self:getBitCount() - 1 do
		if self:readBit(i) == state then return i end 		
	end return nil
end 	 	 		 	

-- Converts the Bitmap to a string (for remote saving, etc.) 	 			
function Bitmap:toString(): string return buffer.tostring(self.map) end
-- Pretty-print a Bitmap in rows for debugging etc.
function Bitmap:print(
	row_size: number?
): ()  		  			 
	local total_bits: number = self:getBitCount()
	local rows: string = "\n" 		  		   
	for i = 0, total_bits - 1 do 		
		rows ..= self:readBit(i) and "1" or "0"  	
		if (i + 1) % (row_size or 8) == 0 then rows ..= '\n' end 	
	end print(rows) return rows 			 	
end
 
-- return module
return Bitmap
