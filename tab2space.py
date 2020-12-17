import glob, sys

class Tab2Space:
    """ Main class """

    @staticmethod
    def reindent( file_name, /, space_size = 4 ):
        """ Reindent selected file """
        file = open( file_name, 'r' )

        reindented_file = []
        for line in file.readlines():
            reindented_file.append( Tab2Space.reindent_line( line, space_size ) )

        file.close()

        file = open( file_name, 'w' )
        file.write( ''.join( reindented_file ) )

    @staticmethod
    def reindent_line( line: str, space_size: int ) -> str:
        """ Reindent line given in argumentes """
        reindented_line = ''
        try:
            char_it = iter( line )

            while True:
                for i in range( 0, space_size ):
                    char = next(char_it)    # it raise StopIteration exception

                    if char != '\t':
                        reindented_line += char
                    else:
                        for _ in range( 0, space_size-i ):
                            reindented_line += ' '
                        break
        except StopIteration:
            pass

        return reindented_line


if __name__ == '__main__':

    for arg_num in range( 1, len(sys.argv) ):
        for file_name in glob.glob( sys.argv[arg_num] ):
            Tab2Space.reindent( file_name, space_size=8 )
            print( f"Reindent {file_name}" )
